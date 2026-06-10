import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Libras', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Tradutor de Lingua de Sinais',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [IconButton(icon: Icon(Icons.settings), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recursos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildResourceCard(
                    context,
                    icon: Icons.translate_outlined,
                    title: 'Texto para Libras',
                    subtitle: 'Utilize texto abaixo',
                    color: const Color(0xFF2563EB),
                    onTap: () => context.go(AppRoutePaths.textToSign),
                  ),
                  _buildResourceCard(
                    context,
                    icon: Icons.sign_language_outlined,
                    title: 'Libras para Texto',
                    subtitle: 'Use a camera para',
                    color: const Color(0xFFDC2626),
                    onTap: () => context.go(AppRoutePaths.camera),
        ),
                  _buildResourceCard(
                    context,
                    icon: Icons.menu_book_rounded,
                    title: 'Dicionario',
                    subtitle: 'Consulte sinais e',
                    color: const Color(0xFF16A34A),
                    onTap: () => context.go(AppRoutePaths.dictionary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: color,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
