import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/router/app_routes.dart';

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
  bool _isTranslating = false;

  // Avatar VLibras
  WebViewController? _webViewController;
  bool _avatarReady = false;
  String _avatarStatus = 'Carregando avatar...';

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
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) {
            setState(() {
              _avatarReady = true;
              _avatarStatus = 'Avatar pronto';
            });
          }
        },
        onWebResourceError: (error) {
          if (mounted) {
            setState(() {
              _avatarReady = false;
              _avatarStatus = 'Erro de rede. Verifique a sua ligação.';
            });
          }
        },
      ))
      ..loadHtmlString('''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    html, body { 
      margin: 0; 
      padding: 0; 
      width: 100vw; 
      height: 100vh; 
      background-color: #ffffff; 
      overflow: hidden;
    }
    #texto-alvo { 
      position: absolute; 
      color: transparent; 
      z-index: -1;
    }
    
    /* FORÇA O VLIBRAS A OCUPAR TODO O ESPAÇO SEM FLUTUAR */
    div[vw] {
      position: absolute !important;
      top: 0 !important;
      left: 0 !important;
      width: 100% !important;
      height: 100% !important;
      margin: 0 !important;
      padding: 0 !important;
      transform: none !important;
      max-width: none !important;
    }
    
    /* Oculta o botão flutuante já que abrimos via script */
    div[vw-access-button] {
      display: none !important;
    }
    
    /* Expande o wrapper interno */
    .vw-plugin-wrapper {
      position: absolute !important;
      top: 0 !important;
      left: 0 !important;
      width: 100vw !important;
      height: 100vh !important;
      margin: 0 !important;
      max-width: none !important;
      background: #ffffff !important;
      border-radius: 0 !important;
    }
  </style>
</head>
<body>
  <div id="texto-alvo"></div>

  <div vw class="enabled">
    <div vw-access-button class="active"></div>
    <div vw-plugin-wrapper>
      <div class="vw-plugin-top-wrapper"></div>
    </div>
  </div>

  <script src="https://vlibras.gov.br/app/vlibras-plugin.js"></script>
  <script>
    new window.VLibras.Widget('https://vlibras.gov.br/app');

    function traduzirPeloVLibras(textoDigitado) {
      var elemento = document.getElementById('texto-alvo');
      elemento.innerText = textoDigitado;
      elemento.click(); 
    }

    var autoOpened = false;
    function tryOpenAvatar() {
      var btn = document.querySelector('[vw-access-button]');
      if (btn && !autoOpened) {
        btn.click();
        autoOpened = true;
      } else if (!autoOpened) {
        setTimeout(tryOpenAvatar, 500);
      }
    }
    setTimeout(tryOpenAvatar, 1000);
  </script>
</body>
</html>
''');

    setState(() => _webViewController = controller);
  }

  // ── Tradução ──────────────────────────────────

  Future<void> _translateText() async {
    final texto = _controller.text;

    if (texto.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite algo para traduzir.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    if (_speechToText.isListening) await _speechToText.stop();

    setState(() {
      _isTranslating = true;
      _avatarStatus = 'A enviar para o VLibras...';
    });

    // Limpa caracteres problemáticos que poderiam quebrar o Javascript
    final escapedText = texto.replaceAll("'", "\\'").replaceAll('"', '\\"').replaceAll('\n', ' ');
    
    // Injeta o texto diretamente no motor oficial do VLibras através da WebView
    await _webViewController?.runJavaScript('traduzirPeloVLibras("$escapedText");');

    setState(() {
      _isTranslating = false;
      _avatarStatus = 'Sinalização em reprodução';
    });
  }

  void _reloadAvatar() {
    setState(() { _avatarReady = false; _avatarStatus = 'A recarregar...'; });
    _webViewController?.reload();
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
              child: Text(_isTranslating ? 'A traduzir...' : 'Traduzir',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        SizedBox(
          height: 420,
          child: _webViewController != null
              ? WebViewWidget(controller: _webViewController!)
              : const Center(child: CircularProgressIndicator(color: Color(0xFF2F80ED))),
        ),
        
        // Barra inferior de status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
          ),
          child: Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _avatarReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _avatarStatus,
                style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: _reloadAvatar,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
              tooltip: 'Recarregar avatar',
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ]),
        ),
      ]),
    );
  }
}