import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/product_models.dart';
import '../../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(apiClient: ref.watch(apiClientProvider)),
);

final productCatalogProvider =
    AsyncNotifierProvider<ProductCatalogNotifier, ProductPage>(
      ProductCatalogNotifier.new,
    );

final productDetailProvider = FutureProvider.autoDispose.family<Product, int>(
  (ref, id) => ref.watch(productRepositoryProvider).getProduct(id),
);

final productCategoriesProvider =
    FutureProvider.autoDispose<List<ProductCategory>>(
      (ref) => ref.watch(productRepositoryProvider).getCategories(),
    );

class ProductCatalogNotifier extends AsyncNotifier<ProductPage> {
  static const pageSize = 10;

  String? query;
  int? categoryId;
  int page = 1;

  ProductRepository get _repository => ref.read(productRepositoryProvider);

  @override
  Future<ProductPage> build() => _load();

  Future<ProductPage> _load() => _repository.getProducts(
    query: query,
    categoryId: categoryId,
    page: page,
    limit: pageSize,
  );

  Future<void> applyFilters({String? query, int? categoryId}) async {
    this.query = query?.trim().isEmpty == true ? null : query?.trim();
    this.categoryId = categoryId;
    page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == this.page) return;
    this.page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}
