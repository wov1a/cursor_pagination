# Практический пример: MVVM + Retrofit + Composite Cursor

Полный пример интеграции библиотеки cursor_pagination с архитектурой MVVM, Retrofit и составным курсором.

---

## 📋 Содержание

1. [Обзор архитектуры](#обзор-архитектуры)
2. [Шаг 1: Модели данных](#шаг-1-модели-данных)
3. [Шаг 2: API Source (Retrofit)](#шаг-2-api-source-retrofit)
4. [Шаг 3: Repository](#шаг-3-repository)
5. [Шаг 4: ViewModel](#шаг-4-viewmodel)
6. [Шаг 5: UI (View)](#шаг-5-ui-view)
7. [Полный пример кода](#полный-пример-кода)

---

## Обзор архитектуры

```
View (UI)
    ↓
ViewModel (CubitPaginationController)
    ↓
Repository
    ↓
API Source (Retrofit)
    ↓
Backend API
```

---

## Шаг 1: Модели данных

### 1.1 Custom Cursor

Простой курсор с ID последнего элемента:

```dart
/// Кастомный курсор для пагинации
class ProductCursor {
  final String? lastSeenId;  // ID последнего элемента
  final int limit;           // Размер страницы

  const ProductCursor({
    this.lastSeenId,
    this.limit = 10,
  });

  /// Создать курсор для первой страницы
  ProductCursor first([int? newLimit]) => ProductCursor(
    limit: newLimit ?? limit,
  );

  /// Обновить курсор новым ID
  ProductCursor updateCursor(String id) {
    return ProductCursor(
      lastSeenId: id,
      limit: limit,
    );
  }
}
```

### 1.2 Entity модели

```dart
/// Модель продукта для отображения
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
```

### 1.3 API Request модель

```dart
/// Модель запроса для API
class ProductsRequest {
  final int? limit;
  final String? lastSeenId;

  ProductsRequest({
    this.limit,
    this.lastSeenId,
  });

  Map<String, dynamic> toJson() => {
    if (limit != null) 'limit': limit,
    if (lastSeenId != null) 'last_seen_id': lastSeenId,
  };
}
```

### 1.4 API Response модель

```dart
/// DTO из API
class ProductDto {
  final String id;
  final String title;
  final String description;

  ProductDto({
    required this.id,
    required this.title,
    required this.description,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) => ProductDto(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
  );
}

/// Response обёртка
class ProductsResponse {
  final List<ProductDto> items;

  ProductsResponse({required this.items});

  factory ProductsResponse.fromJson(Map<String, dynamic> json) =>
      ProductsResponse(
        items: (json['items'] as List)
            .map((item) => ProductDto.fromJson(item))
            .toList(),
      );
}
```

---

## Шаг 2: API Source (Retrofit)

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'products_source.g.dart';

@RestApi(baseUrl: "https://api.example.com/")
abstract class ProductsSource {
  factory ProductsSource(Dio dio, {String baseUrl}) = _ProductsSource;

  /// Получить список продуктов с пагинацией
  @POST("products")
  Future<ProductsResponse> getProducts({
    @Body() required ProductsRequest body,
  });
}
```

---

## Шаг 3: Repository

```dart
import 'package:cursor_pagination/cursor_pagination.dart';

/// Result wrapper для обработки ошибок
sealed class Result<T> {}

class DataResult<T> extends Result<T> {
  final T data;
  DataResult(this.data);
}

class ErrorResult<T> extends Result<T> {
  final String message;
  ErrorResult(this.message);
}

/// Repository для работы с продуктами
class ProductsRepository {
  final ProductsSource _source;

  ProductsRepository(this._source);

  /// Загрузить продукты с пагинацией
  Future<Result<List<Product>>> getProducts(
    ProductCursor cursor,
  ) async {
    try {
      // Формируем запрос
      final request = ProductsRequest(
        limit: cursor.limit,
        lastSeenId: cursor.lastSeenId,
      );

      // Выполняем запрос
      final response = await _source.getProducts(body: request);

      // Маппим DTO в Entity
      final products = response.items
          .map((dto) => Product(
                id: dto.id,
                title: dto.title,
                description: dto.description,
              ))
          .toList();

      return DataResult(products);
    } catch (e) {
      return ErrorResult('Failed to load products: $e');
    }
  }
}
```

---

## Шаг 4: ViewModel

```dart
import 'package:flutter/material.dart';
import 'package:cursor_pagination/cursor_pagination.dart';

class ProductsViewModel {
  final ProductsRepository _repository;

  ProductsViewModel(this._repository);

  /// Контроллер пагинации
  late final paginationController = CubitPaginationController<
    Product,           // ItemType
    ProductCursor,     // CursorType (наш кастомный курсор!)
    String             // ErrorType
  >(
    firstPagePointer: CursorPagination<ProductCursor>(
      cursor: ProductCursor(limit: 10),  // Начальный курсор
      limit: 10,
    ),
    loadFirstPageOnInit: false,  // Загрузим в initState View
    getPageFunc: _fetchPage,
  );

  /// Внутренний метод загрузки страницы
  Future<PaginationResult<Product, ProductCursor, String>> _fetchPage(
    CursorPagination<ProductCursor> pagination,
  ) async {
    try {
      // Извлекаем курсор (или используем начальный)
      final cursor = pagination.cursor ?? ProductCursor(limit: pagination.limit);

      // Загружаем данные через repository
      final result = await _repository.getProducts(cursor);

      switch (result) {
        // Успешная загрузка
        case DataResult<List<Product>>(:final data):
          final products = data;

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

        // Ошибка загрузки
        case ErrorResult<List<Product>>(:final message):
          return ErrorPaginationResult(
            pagination: pagination,
            error: message,
          );
      }
    } catch (e) {
      return ErrorPaginationResult(
        pagination: pagination,
        error: e.toString(),
      );
    }
  }

  /// Очистка ресурсов
  void dispose() {
    paginationController.close();
  }
}
```

---

## Шаг 5: UI (View)

### 5.1 Основной экран

```dart
import 'package:flutter/material.dart';
import 'package:cursor_pagination/cursor_pagination.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Инициализируем ViewModel
    _viewModel = ProductsViewModel(
      ProductsRepository(ProductsSource(Dio())),
    );
    // Загружаем первую страницу
    _viewModel.paginationController.getFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: CubitPaginatedListBuilder<Product, ProductCursor, String>(
        controller: _viewModel.paginationController,

        // 📊 Состояние с данными
        dataBuilder: (context, dataState, isProcessing) {
          final products = dataState.itemList;
          final isLastPage = dataState.isLastItems;

          return RefreshIndicator(
            onRefresh: () async {
              await _viewModel.paginationController.getFirst();
            },
            child: ListView.separated(
              controller: _viewModel.paginationController.scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: products.length + (isLastPage ? 0 : 1),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                // Shimmer индикатор загрузки следующей страницы
                if (index >= products.length) {
                  return const _ProductCardShimmer();
                }

                // Карточка продукта
                final product = products[index];
                return ProductCard(
                  product: product,
                );
              },
            ),
          );
        },

        // 📭 Пустое состояние
        emptyBuilder: (context, emptyState, isProcessing) {
          return const Center(
            child:
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 16, color: Colors.grey,
                ),
            ),
          );
        },

        // ❌ Состояние ошибки
        errorBuilder: (context, errorState, isProcessing) {
          return Center(
            child: Text(
              'Error: ${errorState.description}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
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
```

---

### Структура проекта

```
lib/
├── data/
│   ├── models/
│   │   ├── product_cursor.dart          # Кастомный курсор
│   │   ├── products_request.dart        # API Request
│   │   ├── products_response.dart       # API Response
│   │   └── product.dart                 # Entity модель
│   ├── source/
│   │   └── products_source.dart         # Retrofit API
│   └── repository/
│       └── products_repository.dart     # Repository
├── presentation/
│   ├── viewmodels/
│   │   └── products_viewmodel.dart      # ViewModel
│   └── screens/
│       ├── products_screen.dart         # Главный экран
│       └── widgets/
│           └── product_card.dart        # Карточка продукта
└── core/
    └── result.dart                      # Result wrapper
```
