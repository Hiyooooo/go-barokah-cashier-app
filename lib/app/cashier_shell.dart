import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';

const _navigationItems = <_NavigationItem>[
  _NavigationItem(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: 'Products',
  ),
  _NavigationItem(
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    label: 'Cart',
  ),
  _NavigationItem(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: 'Sales',
  ),
  _NavigationItem(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: 'Account',
  ),
];

class CashierShell extends ConsumerWidget {
  const CashierShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail = constraints.maxWidth >= 840;

        void selectDestination(int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const _ShellBrand(),
            actions: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Center(child: _CashierContext()),
              ),
            ],
          ),
          body: Row(
            children: [
              if (useNavigationRail)
                SafeArea(
                  top: false,
                  child: NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: selectDestination,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final item in _navigationItems)
                        NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(item.label),
                        ),
                    ],
                  ),
                ),
              Expanded(child: navigationShell),
            ],
          ),
          bottomNavigationBar: useNavigationRail
              ? null
              : SafeArea(
                  top: false,
                  child: NavigationBar(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: selectDestination,
                    destinations: [
                      for (final item in _navigationItems)
                        NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: item.label,
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _ShellBrand extends StatelessWidget {
  const _ShellBrand();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.forestGreen,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: const Icon(
          Icons.storefront_outlined,
          size: 18,
          color: AppColors.surface,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text('Go-Barokah', style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

class _CashierContext extends StatelessWidget {
  const _CashierContext();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Role pengguna: cashier',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Text('Kasir', style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _NavigationItem {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
