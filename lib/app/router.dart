import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final isCashier = auth.valueOrNull?.role == 'cashier';

  return GoRouter(
    initialLocation: '/login',
    redirect: (_, state) {
      if (auth.isLoading) return null;
      if (state.matchedLocation == '/login') {
        return isCashier ? '/products' : null;
      }
      return isCashier ? null : '/login';
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/login'),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(
        path: '/products',
        builder: (_, _) => const _PlaceholderPage(title: 'Products'),
      ),
      GoRoute(
        path: '/cart',
        builder: (_, _) => const _PlaceholderPage(title: 'Cart'),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, _) => const _PlaceholderPage(title: 'Checkout'),
      ),
      GoRoute(
        path: '/sales',
        builder: (_, _) => const _PlaceholderPage(title: 'Sales'),
      ),
      GoRoute(
        path: '/receipt/:saleNumber',
        builder: (_, state) => _PlaceholderPage(
          title: 'Receipt ${state.pathParameters['saleNumber']}',
        ),
      ),
      GoRoute(
        path: '/account',
        builder: (_, _) => const _PlaceholderPage(title: 'Account'),
      ),
    ],
  );
});

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
