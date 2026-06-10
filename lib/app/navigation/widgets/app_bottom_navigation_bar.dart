import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: Color(0xFF2563EB), fontSize: 11);
          }
          return const TextStyle(color: Colors.grey, fontSize: 11);
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: _SelectedNavIcon(icon: Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.translate_outlined),
            selectedIcon: _SelectedNavIcon(icon: Icons.translate),
            label: 'Texto→Libras',
          ),
          NavigationDestination(
            icon: Icon(Icons.sign_language_outlined),
            selectedIcon: _SelectedNavIcon(icon: Icons.sign_language),
            label: 'Câmera',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: _SelectedNavIcon(icon: Icons.menu_book),
            label: 'Dicionário',
          ),
        ],
      ),
    );
  }
}

class _SelectedNavIcon extends StatelessWidget {
  const _SelectedNavIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
