import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/domain/user_model.dart';
import '../theme/app_colors.dart';

class _TabDestination {
  const _TabDestination({
    required this.route,
    required this.icon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final String label;
}

const _ownerTabs = [
  _TabDestination(route: '/owner/home', icon: Icons.dashboard_outlined, label: 'Accueil'),
  _TabDestination(route: '/properties', icon: Icons.villa_outlined, label: 'Biens'),
  _TabDestination(route: '/leases', icon: Icons.description_outlined, label: 'Baux'),
  _TabDestination(route: '/payments', icon: Icons.payments_outlined, label: 'Paiements'),
  _TabDestination(route: '/messages', icon: Icons.chat_bubble_outline, label: 'Messages'),
];

const _tenantTabs = [
  _TabDestination(route: '/tenant/home', icon: Icons.dashboard_outlined, label: 'Accueil'),
  _TabDestination(route: '/leases', icon: Icons.description_outlined, label: 'Mon bail'),
  _TabDestination(route: '/payments', icon: Icons.payments_outlined, label: 'Paiements'),
  _TabDestination(route: '/maintenance', icon: Icons.build_outlined, label: 'Maintenance'),
  _TabDestination(route: '/messages', icon: Icons.chat_bubble_outline, label: 'Messages'),
];

/// Scaffold avec barre de navigation persistante — à utiliser sur les 5
/// écrans racines de chaque rôle (accueil, biens/baux, paiements,
/// maintenance/baux, messages). Les écrans "de détail" poussés par-dessus
/// (via `context.push`) restent des `Scaffold` classiques sans barre.
///
/// [currentRoute] est passé explicitement par l'écran appelant (plutôt que
/// déduit de `GoRouterState.of(context)`) pour que ce widget reste
/// testable sans un vrai `GoRouter` dans l'arbre de widgets.
class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final Widget body;
  final String currentRoute;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(authControllerProvider).user?.role == UserRole.owner;
    final tabs = isOwner ? _ownerTabs : _tenantTabs;
    final currentIndex = tabs.indexWhere((tab) => tab.route == currentRoute);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          if (index == currentIndex) return;
          context.go(tabs[index].route);
        },
        items: tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
