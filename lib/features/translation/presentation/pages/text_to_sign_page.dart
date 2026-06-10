import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../utils/libras/libras_export.dart';

class TextToSignPage extends StatefulWidget {
  const TextToSignPage({super.key});

  @override
  State<TextToSignPage> createState() => _TextToSignPageState();
}

class _TextToSignPageState extends State<TextToSignPage> {
  final TextEditingController _controller = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();

  // Speech-to-Text
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isSpeechInitializing = false;
  String? _speechStatusMessage;
  String _lastRecognizedWords = '';

  // Tradução
  List<TranslatedSign>? _translatedSigns;
  bool _isTranslating = false;

  // Avatar VLibras
  WebViewController? _webViewController;
  bool _avatarReady = false;
  bool _isPlaying = false;
  String _avatarStatus = 'Carregando avatar...';
  String _currentGlosa = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeechToText();
    _initWebView();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _controller.dispose();
    super.dispose();
  }

  // ── WebView / Avatar VLibras ──────────────────

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) => _onAvatarMessage(msg.message),
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          Future.delayed(const Duration(seconds: 2), () {
            _webViewController?.runJavaScript(_buildInjectedScript());
          });
        },
        onWebResourceError: (error) {
          if (mounted) {
            setState(() {
              _avatarReady = false;
              _avatarStatus = 'Erro de rede. Verifique sua conexão.';
            });
          }
        },
      ))
      ..loadHtmlString('''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { 
      margin: 0; 
      padding: 0; 
      background-color: transparent; 
    }
  </style>
</head>
<body>
  <div vw class="enabled">
    <div vw-access-button class="active"></div>
    <div vw-plugin-wrapper>
      <div class="vw-plugin-top-wrapper"></div>
    </div>
  </div>

  <script src="https://vlibras.gov.br/app/vlibras-plugin.js"></script>
  <script>
    // Inicialização correta apontando para o diretório
    new window.VLibras.Widget('https://vlibras.gov.br/app');
  </script>
</body>
</html>
''');

    setState(() => _webViewController = controller);
  }

  String _buildInjectedScript() {
    return r'''
(function() {
  var attempts = 0;
  function waitForPlayer() {
    attempts++;
    if (attempts > 120) {
      FlutterBridge.postMessage('error:timeout');
      return;
    }
    var input = document.querySelector('input[placeholder]')
              || document.querySelector('textarea')
              || document.querySelector('input[type=text]');
    if (input) {
      FlutterBridge.postMessage('ready');
      window.traduzir = function(glosa) {
        try {
          var nativeSetter = Object.getOwnPropertyDescriptor(
            window.HTMLInputElement.prototype, 'value'
          );
          if (nativeSetter && nativeSetter.set) {
            nativeSetter.set.call(input, glosa);
          } else {
            input.value = glosa;
          }
          input.dispatchEvent(new Event('input',  { bubbles: true }));
          input.dispatchEvent(new Event('change', { bubbles: true }));
          var buttons = document.querySelectorAll('button');
          var clicked = false;
          buttons.forEach(function(b) {
            var txt = (b.textContent || b.innerText || '').toLowerCase();
            var lbl = (b.getAttribute('aria-label') || '').toLowerCase();
            if (!clicked && (txt.includes('traduz') || txt.includes('ok') || lbl.includes('traduz'))) {
              b.click();
              clicked = true;
            }
          });
          FlutterBridge.postMessage('playing:' + glosa);
        } catch(e) {
          FlutterBridge.postMessage('error:' + e.message);
        }
      };
      return;
    }
    setTimeout(waitForPlayer, 500);
  }
  waitForPlayer();
})();
''';
  }

  void _onAvatarMessage(String message) {
    if (!mounted) return;
    if (message == 'ready') {
      setState(() { _avatarReady = true; _avatarStatus = 'Avatar pronto'; });
    } else if (message.startsWith('playing:')) {
      setState(() { _isPlaying = true; _avatarStatus = 'Reproduzindo sinal...'; });
    } else if (message == 'animationEnd') {
      setState(() { _isPlaying = false; _avatarStatus = 'Pronto'; });
    } else if (message.startsWith('error:')) {
      final detail = message.replaceFirst('error:', '');
      setState(() {
        _isPlaying = false;
        _avatarStatus = detail == 'timeout'
            ? 'Tempo limite — verifique sua conexão'
            : 'Erro: $detail';
      });
    }
  }

  // ── Tradução ──────────────────────────────────

  String _buildGlosa(List<TranslatedSign> signs) {
    return signs.map((s) => s.word.toUpperCase()).join(' ');
  }

  Future<void> _translateText() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite algo para traduzir.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    if (_speechToText.isListening) await _speechToText.stop();

    setState(() {
      _isTranslating = true;
      _translatedSigns = null;
      _isPlaying = false;
      _avatarStatus = 'Processando texto...';
      _currentGlosa = '';
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final signs = LibrasTranslator.translate(_controller.text);
    final glosa = _buildGlosa(signs);

    setState(() {
      _translatedSigns = signs;
      _isTranslating = false;
      _currentGlosa = glosa;
    });

    if (glosa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum sinal encontrado para o texto digitado.')),
      );
      return;
    }

    await _sendGlosaToAvatar(glosa);
  }

  Future<void> _sendGlosaToAvatar(String glosa) async {
    if (_webViewController == null) return;
    final escaped = glosa.replaceAll("'", "\\'");
    await _webViewController!.runJavaScript("window.traduzir('$escaped');");
    setState(() { _isPlaying = true; _avatarStatus = 'Reproduzindo: $glosa'; });
  }

  Future<void> _replayGlosa() async {
    if (_currentGlosa.isEmpty) return;
    await _sendGlosaToAvatar(_currentGlosa);
  }

  void _reloadAvatar() {
    setState(() { _avatarReady = false; _avatarStatus = 'Recarregando...'; });
    _webViewController?.loadRequest(Uri.parse('https://vlibras.gov.br/app'));
  }

  // ── Speech-to-Text ────────────────────────────

  Future<void> _initializeSpeechToText() async {
    if (_isSpeechInitializing) return;
    setState(() => _isSpeechInitializing = true);
    final available = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
      debugLogging: false,
    );
    if (!mounted) return;
    setState(() {
      _speechEnabled = available;
      _isSpeechInitializing = false;
      if (!available) _speechStatusMessage = 'Reconhecimento de voz indisponível.';
    });
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    setState(() {
      _isListening = status == 'listening';
      if (status == 'notListening' || status == 'done') _isListening = false;
    });
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() { _isListening = false; _speechStatusMessage = 'Erro: ${error.errorMsg}'; });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final recognized = result.recognizedWords;
    if (recognized == _lastRecognizedWords) return;
    _lastRecognizedWords = recognized;
    setState(() {
      _controller.text = recognized;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      _speechStatusMessage = null;
    });
  }

  Future<void> _toggleListening() async {
    FocusScope.of(context).unfocus();
    if (_isSpeechInitializing) return;
    if (!_speechEnabled) {
      await _initializeSpeechToText();
      if (!_speechEnabled) return;
    }
    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
      return;
    }
    final locales = await _speechToText.locales();
    String? localeId;
    for (final l in locales) {
      if (l.localeId == 'pt_BR') { localeId = l.localeId; break; }
    }
    localeId ??= locales.firstWhere(
      (l) => l.localeId.startsWith('pt_'),
      orElse: () => locales.first,
    ).localeId;
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: localeId,
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
    );
    if (!mounted) return;
    setState(() { _isListening = true; _speechStatusMessage = null; });
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Texto para Libras'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.pushNamed(AppRouteNames.signToText),
            child: const Text('Libras para Texto'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputCard(),
          const SizedBox(height: 24),
          Text('Avatar VLibras',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildAvatarCard(),
          if (_currentGlosa.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildGlosaCard(),
          ],
          if (_translatedSigns != null && _translatedSigns!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSignsChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Texto em Português',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            onPressed: _toggleListening,
            icon: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded),
            style: IconButton.styleFrom(
              backgroundColor: _isListening ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
              foregroundColor: _isListening ? Colors.white : const Color(0xFF4B5563),
            ),
            tooltip: _isListening ? 'Parar microfone' : 'Ativar microfone',
          ),
        ]),
        if (_speechStatusMessage != null) ...[
          const SizedBox(height: 6),
          Text(_speechStatusMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFDC2626))),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Digite o texto para traduzir...',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Text('${_controller.text.length} caracteres',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          const Spacer(),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: _isTranslating ? null : _translateText,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24)),
              child: Text(_isTranslating ? 'Traduzindo...' : 'Traduzir',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildAvatarCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1e293b), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        SizedBox(
          height: 300,
          child: _webViewController != null
              ? WebViewWidget(controller: _webViewController!)
              : const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFF1e293b),
          child: Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPlaying ? Colors.greenAccent
                    : _avatarReady ? const Color(0xFF38bdf8) : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_avatarStatus,
                  style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              onPressed: _reloadAvatar,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94a3b8)),
              tooltip: 'Recarregar avatar',
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            if (_currentGlosa.isNotEmpty)
              IconButton(
                onPressed: _isPlaying ? null : _replayGlosa,
                icon: const Icon(Icons.replay_rounded, color: Color(0xFF38bdf8)),
                tooltip: 'Repetir',
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildGlosaCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.translate_rounded, size: 15, color: Color(0xFF0284C7)),
          const SizedBox(width: 6),
          Text('Glosa enviada ao avatar',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF0284C7), fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        Text(_currentGlosa,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: Color(0xFF0C4A6E), letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _buildSignsChips() {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Sinais identificados',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Wrap(
          spacing: 8, runSpacing: 8,
          children: _translatedSigns!.map((sign) {
            final hasVideo = sign.videoPaths.isNotEmpty || sign.isFound;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasVideo ? cs.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: hasVideo ? cs.primary.withOpacity(0.3) : const Color(0xFFE5E7EB)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(hasVideo ? Icons.check_circle_rounded : Icons.help_outline_rounded,
                    size: 12, color: hasVideo ? cs.primary : Colors.grey),
                const SizedBox(width: 4),
                Text(sign.word,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: hasVideo ? cs.primary : Colors.grey)),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}
