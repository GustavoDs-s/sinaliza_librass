import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/claude_service.dart';
import '../../../../services/history_service.dart';
import '../../../../models/translation_entry.dart';
import '../widgets/camera_view_widget.dart';
import '../widgets/translation_result_widget.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import 'camera_history_page.dart';

class CameraTranslatePage extends StatefulWidget {
  const CameraTranslatePage({super.key});

  @override
  State<CameraTranslatePage> createState() => _CameraTranslatePageState();
}

class _CameraTranslatePageState extends State<CameraTranslatePage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _cameraError = false;
  String _cameraErrorMsg = '';

  TranslationState _translationState = TranslationState.idle;
  String? _translationText;
  bool _isTranslating = false;

  bool _autoMode = false;
  int _autoCountdown = 5;
  int _autoInterval = 5;
  Timer? _autoTimer;

  final FlutterTts _tts = FlutterTts();
  bool _ttsAvailable = false;

  final HistoryService _historyService = HistoryService();
  ClaudeService? _claudeService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    await _loadApiKey();
    await _initTts();
    await _initCamera();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('anthropic_api_key');
    if (key?.isNotEmpty == true) {
      setState(() => _claudeService = ClaudeService(apiKey: key!));
    }
    final interval = prefs.getInt('auto_interval') ?? 5;
    setState(() => _autoInterval = interval);
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(0.9);
      await _tts.setVolume(1.0);
      setState(() => _ttsAvailable = true);
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() { _cameraError = true; _cameraErrorMsg = 'Permissão de câmera negada.'; });
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() { _cameraError = true; _cameraErrorMsg = 'Nenhuma câmera encontrada.'; });
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(camera, ResolutionPreset.medium,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() { _cameraController = ctrl; _cameraReady = true; _cameraError = false; });
    } catch (e) {
      setState(() { _cameraError = true; _cameraErrorMsg = 'Erro ao iniciar câmera: $e'; });
    }
  }

  Future<void> _captureAndTranslate() async {
    if (_isTranslating || _cameraController == null || !_cameraReady) return;
    if (_claudeService == null) { _showApiKeyDialog(); return; }
    setState(() { _isTranslating = true; _translationState = TranslationState.loading; });
    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();
      final result = await _claudeService!.translateSign(bytes);
      await _historyService.saveEntry(TranslationEntry(text: result, timestamp: DateTime.now()));
      if (mounted) setState(() { _translationText = result; _translationState = TranslationState.success; });
    } catch (e) {
      if (mounted) setState(() {
        _translationText = e.toString().replaceFirst('Exception: ', '');
        _translationState = TranslationState.error;
      });
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  void _toggleAutoMode(bool value) {
    setState(() { _autoMode = value; _autoCountdown = _autoInterval; });
    if (value) {
      _autoTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _autoCountdown--);
        if (_autoCountdown <= 0) {
          setState(() => _autoCountdown = _autoInterval);
          _captureAndTranslate();
        }
      });
    } else {
      _autoTimer?.cancel();
      _autoTimer = null;
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.key_rounded),
        title: const Text('API Key necessária'),
        content: const Text('Configure sua chave da API Anthropic nas configurações.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Depois')),
          FilledButton(
            onPressed: () { Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))
                  .then((_) => _loadApiKey()); },
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) _cameraController?.dispose();
    else if (state == AppLifecycleState.resumed) _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoTimer?.cancel();
    _cameraController?.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.sign_language_rounded, color: cs.primary, size: 22),
          const SizedBox(width: 8),
          const Text('Câmera → Texto'),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.history_rounded), tooltip: 'Histórico',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CameraHistoryPage()))),
          IconButton(icon: const Icon(Icons.settings_rounded), tooltip: 'Configurações',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()))
                  .then((_) => _loadApiKey())),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Card(clipBehavior: Clip.antiAlias, child: _buildCameraArea()),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _cameraReady && !_autoMode ? _captureAndTranslate : null,
                  icon: _isTranslating
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt_rounded),
                  label: Text(_isTranslating ? 'Analisando...' : 'Capturar sinal'),
                ),
              ),
              const SizedBox(width: 10),
              _AutoToggle(value: _autoMode, onChanged: _cameraReady ? _toggleAutoMode : null),
            ]),
            const SizedBox(height: 12),
            TranslationResultWidget(
              state: _translationState,
              text: _translationText,
              onSpeak: _ttsAvailable ? () => _tts.speak(_translationText!) : null,
              onClear: () => setState(() { _translationText = null; _translationState = TranslationState.idle; }),
            ),
            const SizedBox(height: 12),
            _TipsCard(),
          ]),
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    if (_cameraError) {
      return Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.videocam_off_rounded, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(_cameraErrorMsg, textAlign: TextAlign.center),
          ])));
    }
    if (!_cameraReady || _cameraController == null) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(), SizedBox(height: 12), Text('Iniciando câmera...'),
      ]));
    }
    return CameraViewWidget(
      controller: _cameraController!,
      isAutoMode: _autoMode,
      autoCountdown: _autoCountdown,
      onCapture: _captureAndTranslate,
    );
  }
}

class _AutoToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _AutoToggle({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: value ? cs.primary : cs.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        color: value ? cs.primaryContainer : Colors.transparent,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.auto_mode_rounded, size: 16,
            color: value ? cs.primary : cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text('Auto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: value ? cs.primary : cs.onSurfaceVariant)),
        const SizedBox(width: 6),
        Switch(value: value, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ]),
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.tertiary.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lightbulb_outline_rounded, size: 15, color: cs.tertiary),
          const SizedBox(width: 6),
          Text('Dicas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.tertiary)),
        ]),
        const SizedBox(height: 8),
        for (final tip in [
          'Boa iluminação melhora o reconhecimento',
          'Posicione as mãos dentro da moldura guia',
          'Faça o sinal de frente para a câmera',
          'Use modo Auto para tradução contínua',
        ])
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 6),
                  child: Container(width: 4, height: 4,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: cs.onSurfaceVariant.withOpacity(0.5)))),
              const SizedBox(width: 8),
              Expanded(child: Text(tip, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
            ]),
          ),
      ]),
    );
  }
}
