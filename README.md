# Cursor Pagination

A flexible and powerful cursor-based pagination library for Flutter with full generic type support.

[![Pub Version](https://img.shields.io/pub/v/cursor_pagination)](https://pub.dev/packages/cursor_pagination)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 🎯 **Full Generic Type Support** - Use any cursor type (String, int, DateTime, custom types)
- 🔄 **Multiple State Management** - Works with ChangeNotifier, BLoC/Cubit
- 📜 **Auto-loading** - Automatically loads next page when scrolling near bottom
- 🎨 **Flexible State Handling** - Separate states for data, empty, and error
- 🛠️ **Item Manipulation** - Update or remove items without refetching
- 🚀 **Production Ready** - Well-tested and documented
- 💪 **Type Safe** - Leverages Dart's strong typing system

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  cursor_pagination: ^1.0.0
  flutter_bloc: ^8.1.0 # Only if using CubitPaginationController
```

## 🚀 Quick Start

### 1. Define Your Models

```dart
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

  ProductCursor updateCursor(String id) {
    return ProductCursor(lastSeenId: id, limit: limit);
  }
}
```

### 2. Create a Controller

#### Option A: Using CubitPaginationController (Recommended)

```dart
final controller = CubitPaginationController<Product, ProductCursor, String>(
  firstPagePointer: CursorPagination<ProductCursor>(
    cursor: ProductCursor(limit: 10),
    limit: 10,
  ),
  getPageFunc: (pagination) async {
    try {
      // Извлекаем курсор
      final cursor = pagination.cursor ?? ProductCursor(limit: pagination.limit);

      // Загружаем данные через API/Repository
      final products = await repository.getProducts(cursor);

      // Определяем курсор для следующей страницы
      final nextCursor = products.isNotEmpty
          ? cursor.updateCursor(products.last.id)
          : cursor;

      return SuccessPaginationResult(
        itemList: products,
        pagination: CursorPagination<ProductCursor>(
          cursor: nextCursor,
          limit: pagination.limit,
        ),
      );
    } catch (e) {
      return ErrorPaginationResult(
        pagination: pagination,
        error: e.toString(),
      );
    }
  },
);
```

#### Option B: Using FlutterPaginationController (ChangeNotifier)

```dart
final controller = FlutterPaginationController<Product, ProductCursor, String>(
  firstPagePointer: CursorPagination<ProductCursor>(
    cursor: ProductCursor(limit: 10),
    limit: 10,
  ),
  getPageFunc: (pagination) async {
    // Same as above
  },
);
```

### 3. Build Your UI

#### With CubitPaginationController (Recommended)

```dart
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final CubitPaginationController<Product, ProductCursor, String> controller;

  @override
  void initState() {
    super.initState();
    controller = CubitPaginationController(
      firstPagePointer: CursorPagination<ProductCursor>(
        cursor: ProductCursor(limit: 10),
        limit: 10,
      ),
      getPageFunc: _fetchProducts,
    );
    controller.getFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: CubitPaginatedListBuilder<Product, ProductCursor, String>(
        controller: controller,

        // 📊 Состояние с данными
        dataBuilder: (context, dataState, isProcessing) {
          final products = dataState.itemList;
          final isLastPage = dataState.isLastItems;

          return RefreshIndicator(
            onRefresh: () async => controller.getFirst(),
            child: ListView.separated(
              controller: controller.scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: products.length + (isLastPage ? 0 : 1),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                // Shimmer индикатор загрузки
                if (index >= products.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Карточка продукта
                final product = products[index];
                return Card(
                  child: ListTile(
                    title: Text(product.title),
                    subtitle: Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          );
        },

        // 📭 Пустое состояние
        emptyBuilder: (context, _, __) => const Center(
          child: Text('No products found'),
        ),

        // ❌ Состояние ошибки
        errorBuilder: (context, errorState, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${errorState.description}'),
              ElevatedButton(
                onPressed: controller.getFirst,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }
}
```

#### With FlutterPaginationController

```dart
class ProductsScreen extends StatefulWidget {
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final FlutterPaginationController<Product, ProductCursor, String> controller;

  @override
  void initState() {
    super.initState();
    controller = FlutterPaginationController(
      firstPagePointer: CursorPagination<ProductCursor>(
        cursor: ProductCursor(limit: 10),
        limit: 10,
      ),
      getPageFunc: _fetchProducts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final state = controller.state;

          return switch (state) {
            DataListPCState(:final itemList, :final isLastItems) => ListView.builder(
              controller: controller.scrollController,
              itemCount: itemList.length + (isLastItems ? 0 : 1),
              itemBuilder: (context, index) {
                if (index >= itemList.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final product = itemList[index];
                return Card(
                  child: ListTile(
                    title: Text(product.title),
                    subtitle: Text(product.description),
                  ),
                );
              },
            ),
            EmptyListPCState() => const Center(
              child: Text('No products found'),
            ),
            ErrorListPCState(:final description) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $description'),
                  ElevatedButton(
                    onPressed: controller.getFirst,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          };
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

## 📚 Advanced Usage

### Different Cursor Types

#### String Cursor (Token-based)

```dart
final controller = CubitPaginationController<Product, String, String>(
  firstPagePointer: const CursorPagination<String>(limit: 20),
  getPageFunc: (pagination) async {
    final products = await api.getProducts(
      cursor: pagination.cursor,
      limit: pagination.limit,
    );

    return SuccessPaginationResult(
      itemList: products.items,
      pagination: pagination.updateCursor(products.nextCursor),
    );
  },
);
```

#### Integer Cursor (Offset-based)

```dart
final controller = CubitPaginationController<Product, int, String>(
  firstPagePointer: const CursorPagination<int>(cursor: 0, limit: 10),
  getPageFunc: (pagination) async {
    final products = await api.getProducts(
      offset: pagination.cursor ?? 0,
      limit: pagination.limit,
    );

    return SuccessPaginationResult(
      itemList: products,
      pagination: pagination.updateCursor(
        (pagination.cursor ?? 0) + products.length,
      ),
    );
  },
);
```

#### DateTime Cursor (Time-based)

```dart
final controller = CubitPaginationController<Message, DateTime, String>(
  firstPagePointer: CursorPagination<DateTime>(
    cursor: DateTime.now(),
    limit: 50,
  ),
  getPageFunc: (pagination) async {
    final messages = await api.getMessages(
      before: pagination.cursor,
      limit: pagination.limit,
    );

    return SuccessPaginationResult(
      itemList: messages,
      pagination: pagination.updateCursor(messages.last.timestamp),
    );
  },
);
```

#### Custom Cursor Type (Composite)

```dart
/// Кастомный курсор с несколькими полями
class ProductCursor {
  final String? lastSeenId;
  final int limit;

  const ProductCursor({this.lastSeenId, this.limit = 10});

  ProductCursor updateCursor(String id) {
    return ProductCursor(lastSeenId: id, limit: limit);
  }
}

final controller = CubitPaginationController<Product, ProductCursor, String>(
  firstPagePointer: CursorPagination<ProductCursor>(
    cursor: const ProductCursor(limit: 10),
    limit: 10,
  ),
  getPageFunc: (pagination) async {
    final cursor = pagination.cursor ?? ProductCursor(limit: pagination.limit);
    final products = await repository.getProducts(cursor);

    final nextCursor = products.isNotEmpty
        ? cursor.updateCursor(products.last.id)
        : cursor;

    return SuccessPaginationResult(
      itemList: products,
      pagination: CursorPagination<ProductCursor>(
        cursor: nextCursor,
        limit: pagination.limit,
      ),
    );
  },
);
```

### Manual Operations

```dart
// Загрузить первую страницу (сброс)
controller.getFirst();

// Загрузить следующую страницу вручную
controller.getNext();

// Обновить текущую страницу
controller.refreshCurrent();

// Обновить конкретный элемент
controller.updateItemAt(index, updatedProduct);

// Удалить конкретный элемент
controller.removeItemAt(index);
```

### Listen to Processing State

```dart
ValueListenableBuilder<bool>(
  valueListenable: controller.isProcessing,
  builder: (context, isProcessing, child) {
    return ElevatedButton(
      onPressed: isProcessing ? null : controller.getFirst,
      child: isProcessing
        ? CircularProgressIndicator()
        : Text('Refresh'),
    );
  },
);
```

### Custom Scroll Threshold

```dart
// The default threshold is 200px from bottom
// To customize, you can extend the controller or adjust the scroll listener
```

## 🏗️ Architecture

### Type Parameters

All controllers use three generic types:

1. **ItemType** - The type of items being paginated (e.g., `User`, `Post`)
2. **CursorType** - The type of cursor (e.g., `String`, `int`, `DateTime`)
3. **ErrorType** - The type for error information (e.g., `String`, custom error class)

### States

The controller can be in one of three states:

- **DataListPCState** - Contains loaded items, pagination info, and last page flag
- **EmptyListPCState** - No items found (first page returned empty)
- **ErrorListPCState** - An error occurred during pagination

### Results

Your `getPageFunc` should return one of:

- **SuccessPaginationResult** - Contains items and updated pagination
- **ErrorPaginationResult** - Contains error information

## 🎯 Best Practices

1. **Always handle errors** in your `getPageFunc`
2. **Update cursor correctly** after each successful fetch
3. **Use appropriate cursor type** for your API (String tokens, int offsets, DateTime, etc.)
4. **Dispose controllers** in StatefulWidget's dispose method
5. **Reuse scroll controller** if you need custom scroll behavior
6. **Test pagination** with different data sizes (empty, single page, multiple pages)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Credits

Created and maintained by the Flutter community.
# cursor_pagination
