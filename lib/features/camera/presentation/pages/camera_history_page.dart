import 'package:flutter/material.dart';
import '../../../../services/history_service.dart';
import '../../../../models/translation_entry.dart';

class CameraHistoryPage extends StatefulWidget {
  const CameraHistoryPage({super.key});

  @override
  State<CameraHistoryPage> createState() => _CameraHistoryPageState();
}

class _CameraHistoryPageState extends State<CameraHistoryPage> {
  final _historyService = HistoryService();
  List<TranslationEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _historyService.loadHistory();
    setState(() { _entries = entries; _loading = false; });
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar histórico'),
        content: const Text('Deseja remover todas as traduções salvas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Limpar')),
        ],
      ),
    );
    if (confirm == true) {
      await _historyService.clearHistory();
      setState(() => _entries = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico — Câmera'),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Limpar', onPressed: _clearAll),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.history_rounded, size: 64, color: cs.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Nenhuma tradução salva',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = _entries[i];
                    final diff = DateTime.now().difference(e.timestamp);
                    final time = diff.inMinutes < 1 ? 'Agora'
                        : diff.inHours < 1 ? 'Há ${diff.inMinutes} min'
                        : diff.inHours < 24 ? 'Há ${diff.inHours}h'
                        : '${e.timestamp.day}/${e.timestamp.month} ${e.timestamp.hour}:${e.timestamp.minute.toString().padLeft(2, '0')}';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Icon(Icons.sign_language_rounded, size: 18, color: cs.primary),
                        ),
                        title: Text(e.text, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(time, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                      ),
                    );
                  },
                ),
    );
  }
}
