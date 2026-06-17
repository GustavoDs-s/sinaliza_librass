import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sinaliza', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Tradutor e Dicionário',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Configurações',
            onPressed: () {
              // Pode adicionar a navegação para a tela de configurações aqui no futuro
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Banner de Boas-Vindas e Destaque ──
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Novidade', 
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tradução por Inteligência Artificial',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Experimente a nossa ferramenta de visão computacional que lê seus sinais em tempo real.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ),
            ),

            // ── 2. Acesso Rápido ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Acesso Rápido', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Texto →\nLibras',
                      icon: Icons.translate_rounded,
                      color: const Color(0xFF2563EB), // Azul
                      onTap: () => context.go(AppRoutePaths.textToSign),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Câmera →\nTexto',
                      icon: Icons.camera_alt_rounded,
                      color: const Color(0xFFDC2626), // Vermelho
                      onTap: () => context.go(AppRoutePaths.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Dicionário\nVirtual',
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF10B981), // Verde
                      onTap: () => context.go(AppRoutePaths.dictionary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── 3. Aprenda Mais (Seção de Matérias) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Descubra a Libras', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Ver tudo'),
                  ),
                ],
              ),
            ),
            
            // Lista horizontal de cards de matérias
            SizedBox(
              height: 220,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildArticleCard(
                    context,
                    title: 'A Importância da Expressão Facial',
                    category: 'Gramática',
                    readTime: '3 min de leitura',
                    imageUrl: 'https://images.unsplash.com/photo-1524601500432-1e1a4c71d692?q=80&w=600&auto=format&fit=crop',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildArticleCard(
                    context,
                    title: 'Como a Libras foi reconhecida no Brasil?',
                    category: 'História',
                    readTime: '5 min de leitura',
                    imageUrl: 'https://images.unsplash.com/photo-1577415124269-fc1140a69e91?q=80&w=600&auto=format&fit=crop',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildArticleCard(
                    context,
                    title: 'Mitos e Verdades sobre a Comunidade Surda',
                    category: 'Cultura',
                    readTime: '4 min de leitura',
                    imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953eb1b5ae?q=80&w=600&auto=format&fit=crop',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Widgets auxiliares para manter o código limpo
  // ──────────────────────────────────────────────────────────────

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, {
    required String title,
    required String category,
    required String readTime,
    required String imageUrl,
    required Color color,
  }) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('A matéria "$title" estará disponível em breve!')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem da matéria
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Textos da matéria
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        readTime,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}