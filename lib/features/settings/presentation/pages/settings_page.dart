import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  bool _obscure = true;
  int _autoInterval = 5;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('anthropic_api_key') ?? '';
      _autoInterval = prefs.getInt('auto_interval') ?? 5;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('anthropic_api_key', _apiKeyController.text.trim());
    await prefs.setInt('auto_interval', _autoInterval);
    setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  void dispose() { _apiKeyController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Credenciais', style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.primary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chave da API Anthropic', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('Usada pela aba Câmera → Texto',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            Text('Obtenha em: console.anthropic.com',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary)),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.security_rounded, size: 16, color: cs.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(child: Text('A chave é armazenada localmente no dispositivo.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onTertiaryContainer))),
              ]),
            ),
          ],
        ))),
        const SizedBox(height: 16),
        Text('Captura automática', style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.primary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Intervalo de captura', style: Theme.of(context).textTheme.titleSmall),
              Text('$_autoInterval segundos',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500)),
            ]),
            Slider(value: _autoInterval.toDouble(), min: 3, max: 15, divisions: 12,
                label: '$_autoInterval s',
                onChanged: (v) => setState(() => _autoInterval = v.round())),
            Text('Tempo entre capturas no modo automático',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ))),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _save,
          icon: Icon(_saved ? Icons.check_rounded : Icons.save_rounded),
          label: Text(_saved ? 'Salvo!' : 'Salvar configurações'),
        ),
      ]),
    );
  }
}
