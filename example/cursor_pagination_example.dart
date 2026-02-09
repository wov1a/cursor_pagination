import 'package:cursor_pagination/cursor_pagination.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cursor Pagination Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProductsScreen(),
    );
  }
}

// ============================================================================
// MODELS
// ============================================================================

/// Модель продукта
class Product {
  final String id;
  final String title;
  final String description;

  const Product({
    required this.id,
    required this.title,
    required this.description,
  });
}

/// Кастомный курсор для пагинации
class ProductCursor {
  final String? lastSeenId;
  final int limit;

  const ProductCursor({this.lastSeenId, this.limit = 10});

  ProductCursor first([int? newLimit]) =>
      ProductCursor(limit: newLimit ?? limit);

  ProductCursor updateCursor(String id) {
    return ProductCursor(lastSeenId: id, limit: limit);
  }
}

// ============================================================================
// MOCK REPOSITORY
// ============================================================================

/// Mock repository с фейковыми данными
class MockProductsRepository {
  // Имитация базы данных продуктов
  static final List<Product> _allProducts = List.generate(
    50,
    (index) => Product(
      id: 'product_$index',
      title: 'Product ${index + 1}',
      description:
          'This is a detailed description of product ${index + 1}. '
          'It contains all the information you need.',
    ),
  );

  /// Загрузить продукты с пагинацией
  Future<List<Product>> getProducts(ProductCursor cursor) async {
    // Имитация задержки сети
    await Future.delayed(const Duration(milliseconds: 800));

    // Найти индекс последнего элемента
    int startIndex = 0;
    if (cursor.lastSeenId != null) {
      startIndex =
          _allProducts.indexWhere((p) => p.id == cursor.lastSeenId) + 1;
    }

    // Вернуть следующую порцию
    final endIndex = (startIndex + cursor.limit).clamp(0, _allProducts.length);
    return _allProducts.sublist(startIndex, endIndex);
  }
}

// ============================================================================
// VIEWMODEL
// ============================================================================

class ProductsViewModel {
  final MockProductsRepository _repository;

  ProductsViewModel(this._repository);

  /// Контроллер пагинации
  late final paginationController =
      CubitPaginationController<Product, ProductCursor, String>(
        firstPagePointer: CursorPagination<ProductCursor>(
          cursor: const ProductCursor(limit: 10),
          limit: 10,
        ),
        loadFirstPageOnInit: false,
        getPageFunc: _fetchPage,
      );

  /// Внутренний метод загрузки страницы
  Future<PaginationResult<Product, ProductCursor, String>> _fetchPage(
    CursorPagination<ProductCursor> pagination,
  ) async {
    try {
      final cursor =
          pagination.cursor ?? ProductCursor(limit: pagination.limit);

      // Загружаем данные через repository
      final products = await _repository.getProducts(cursor);

      // Определяем курсор для следующей страницы
      final nextCursor = products.isNotEmpty
          ? cursor.updateCursor(products.last.id)
          : cursor.first();

      return SuccessPaginationResult(
        itemList: products,
        pagination: CursorPagination<ProductCursor>(
          cursor: nextCursor,
          limit: pagination.limit,
        ),
      );
    } catch (e) {
      return ErrorPaginationResult(pagination: pagination, error: e.toString());
    }
  }

  void dispose() {
    paginationController.close();
  }
}

// ============================================================================
// UI - MAIN SCREEN
// ============================================================================

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductsViewModel(MockProductsRepository());
    _viewModel.paginationController.getFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _viewModel.paginationController.getFirst(),
          ),
        ],
      ),
      body: CubitPaginatedListBuilder<Product, ProductCursor, String>(
        controller: _viewModel.paginationController,

        // 📊 Состояние с данными
        dataBuilder: (context, dataState, isProcessing) {
          final products = dataState.itemList;
          final isLastPage = dataState.isLastItems;

          return Column(
            children: [
              if (isProcessing) const LinearProgressIndicator(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _viewModel.paginationController.getFirst();
                  },
                  child: ListView.separated(
                    controller:
                        _viewModel.paginationController.scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length + (isLastPage ? 0 : 1),
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      // Shimmer индикатор загрузки следующей страницы
                      if (index >= products.length) {
                        return const ProductCardShimmer();
                      }

                      // Карточка продукта
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tapped: ${product.title}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },

        // 📭 Пустое состояние
        emptyBuilder: (context, emptyState, isProcessing) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        },

        // ❌ Состояние ошибки
        errorBuilder: (context, errorState, isProcessing) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${errorState.description}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _viewModel.paginationController.getFirst();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}

// ============================================================================
// UI - PRODUCT CARD
// ============================================================================

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название
              Text(
                product.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Описание
              Text(
                product.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// UI - SHIMMER LOADING
// ============================================================================

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title shimmer
            Container(
              width: double.infinity,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),

            // Description shimmer
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
