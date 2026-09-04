import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/account/presentation/pages/account_page.dart';
import '../features/cart/presentation/pages/cart_page.dart';
import '../features/checkout/presentation/pages/checkout_page.dart';
import '../features/products/presentation/pages/product_detail_page.dart';
import '../features/products/presentation/pages/products_page.dart';
import '../features/receipt/presentation/pages/receipt_page.dart';
import '../features/receipt/presentation/pages/receipt_print_preview_page.dart';
import '../features/sales/presentation/pages/cash_sale_history_page.dart';

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
      GoRoute(path: '/products', builder: (_, _) => const ProductsPage()),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) => ProductDetailPage(
          productId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/cart', builder: (_, _) => const CartPage()),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutPage()),
      GoRoute(path: '/sales', builder: (_, _) => const CashSaleHistoryPage()),
      GoRoute(
        path: '/receipt/:saleNumber',
        builder: (_, state) =>
            ReceiptPage(saleNumber: state.pathParameters['saleNumber']!),
      ),
      GoRoute(
        path: '/receipt/:saleNumber/print',
        builder: (_, state) => ReceiptPrintPreviewPage(
          saleNumber: state.pathParameters['saleNumber']!,
        ),
      ),
      GoRoute(path: '/account', builder: (_, _) => const AccountPage()),
    ],
  );
});
