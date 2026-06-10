import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TranslationState { idle, loading, success, error }

class TranslationResultWidget extends StatelessWidget {
  final TranslationState state;
  final String? text;
  final VoidCallback? onSpeak;
  final VoidCallback? onClear;

  const TranslationResultWidget({
    super.key,
    required this.state,
    this.text,
    this.onSpeak,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.translate_rounded, size: 17, color: cs.primary),
            const SizedBox(width: 8),
            Text('Tradução', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: cs.primary, letterSpacing: 0.5)),
            const Spacer(),
            if (state == TranslationState.success && text != null) ...[
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copiar',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Texto copiado!'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating),
                  );
                },
                style: IconButton.styleFrom(minimumSize: const Size(32, 32), padding: const EdgeInsets.all(6)),
              ),
              if (onSpeak != null)
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  tooltip: 'Ouvir',
                  onPressed: onSpeak,
                  style: IconButton.styleFrom(minimumSize: const Size(32, 32), padding: const EdgeInsets.all(6)),
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Limpar',
                onPressed: onClear,
                style: IconButton.styleFrom(minimumSize: const Size(32, 32), padding: const EdgeInsets.all(6)),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (state) {
      case TranslationState.idle:
        return Row(children: [
          Icon(Icons.pan_tool_rounded, size: 20, color: cs.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(width: 10),
          Expanded(child: Text('Posicione suas mãos na câmera\ne capture o sinal',
              style: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.6), fontStyle: FontStyle.italic))),
        ]);
      case TranslationState.loading:
        return Row(children: [
          SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
          const SizedBox(width: 12),
          Text('Analisando sinal...', style: TextStyle(color: cs.onSurfaceVariant)),
        ]);
      case TranslationState.error:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.error_outline_rounded, size: 18, color: cs.error),
            const SizedBox(width: 8),
            Expanded(child: Text(text ?? 'Erro ao analisar o sinal.',
                style: TextStyle(color: cs.onErrorContainer))),
          ]),
        );
      case TranslationState.success:
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(text ?? '', key: ValueKey(text),
              style: const TextStyle(fontSize: 16, height: 1.6)),
        );
    }
  }
}
