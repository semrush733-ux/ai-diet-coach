import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/l10n_ext.dart';
import '../../features/authentication/application/auth_controller.dart';
import '../../shared/widgets/states.dart';

/// Main app shell: 4-tab bottom navigation + persistent AI Coach FAB.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(l10n.logout),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: navigationShell,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'ai-coach',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.aiCoach}: ${l10n.comingSoon}')),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: Text(l10n.aiCoach),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_outlined),
            selectedIcon: const Icon(Icons.restaurant_menu_rounded),
            label: l10n.navDiet,
          ),
          NavigationDestination(
            icon: const Icon(Icons.water_drop_outlined),
            selectedIcon: const Icon(Icons.water_drop_rounded),
            label: l10n.navSugar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: l10n.navProgress,
          ),
        ],
      ),
    );
  }
}

/// Honest placeholder for tabs whose modules land in later phases.
class ComingSoonTab extends StatelessWidget {
  const ComingSoonTab(
      {super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: context.l10n.comingSoon,
      message: message,
    );
  }
}
