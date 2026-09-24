import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'cashier_shell.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/account/presentation/pages/account_page.dart';
import '../features/cart/presentation/pages/cart_page.dart';
import '../features/checkout/presentation/pages/checkout_page.dart';
import '../features/checkout/presentation/pages/order_review_page.dart';
import '../features/products/presentation/pages/product_detail_page.dart';
import '../features/products/presentation/pages/products_page.dart';
import '../features/receipt/presentation/pages/receipt_page.dart';
import '../features/receipt/presentation/pages/receipt_print_preview_page.dart';
import '../features/receipt/data/models/receipt_models.dart';
import '../features/sales/presentation/pages/cash_sale_history_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final sessionExpired = ref.watch(sessionExpiredProvider);
  final isCashier = auth.valueOrNull?.role == 'cashier';

  return GoRouter(
    initialLocation: '/login',
    redirect: (_, state) {
      if (auth.isLoading) return null;
      if (state.matchedLocation == '/login') {
        return isCashier ? '/products' : null;
      }
      if (isCashier) return null;
      return sessionExpired ? '/login?reason=session_expired' : '/login';
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/login'),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            CashierShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (_, _) => const ProductsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/cart', builder: (_, _) => const CartPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sales',
                builder: (_, _) => const CashSaleHistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/account', builder: (_, _) => const AccountPage()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) => productDetailRoute(state.pathParameters['id']),
      ),
      GoRoute(
        path: '/order-review',
        builder: (_, _) => const OrderReviewPage(),
      ),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutPage()),
      GoRoute(
        path: '/receipt/:saleNumber',
        builder: (_, state) {
          final saleNumber = state.pathParameters['saleNumber'] ?? '';
          return saleNumber.trim().isEmpty
              ? const RouteErrorPage(message: 'Receipt not found.')
              : ReceiptPage(
                  saleNumber: saleNumber,
                  initialReceipt: state.extra is Receipt
                      ? state.extra as Receipt
                      : null,
                );
        },
      ),
      GoRoute(
        path: '/receipt/:saleNumber/print',
        builder: (_, state) => ReceiptPrintPreviewPage(
          saleNumber: state.pathParameters['saleNumber']!,
          initialReceipt: state.extra is Receipt
              ? state.extra as Receipt
              : null,
        ),
      ),
    ],
    errorBuilder: (_, state) =>
        RouteErrorPage(message: state.error?.message ?? 'Page not found.'),
  );
});

Widget productDetailRoute(String? rawId) {
  final productId = int.tryParse(rawId ?? '');
  return productId == null || productId < 1
      ? const RouteErrorPage(message: 'Produk tidak ditemukan.')
      : ProductDetailPage(productId: productId);
}

class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Page unavailable')),
    body: Center(child: Text(message)),
  );
}
