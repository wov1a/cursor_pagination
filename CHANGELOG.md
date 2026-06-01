## 1.0.1

- Widened SDK constraint: `>=3.0.0 <4.0.0` (was `^3.10.4`) — works with any Dart 3.x
- Widened flutter_bloc constraint: `>=8.0.0 <10.0.0` (was `^8.1.0`) — supports bloc 8.x and 9.x

## 1.0.0

### Initial Release 🎉

- ✨ Full generic type support for cursors (String, int, DateTime, custom types)
- 🔄 Two controller implementations:
  - `FlutterPaginationController` for ChangeNotifier-based apps
  - `CubitPaginationController` for BLoC/Cubit pattern
- 📜 Auto-loading pagination on scroll
- 🎨 Three distinct states: Data, Empty, and Error
- 🛠️ Item manipulation methods (update/remove)
- 📊 Processing state tracking with `isProcessing` notifier
- 🎯 Type-safe error handling
- 📚 Comprehensive documentation and examples
- 🧪 Production-ready implementation

### Features

- **Flexible Cursor Types**: Use any type as cursor (String, int, DateTime, or custom)
- **State Management**: Works with both ChangeNotifier and BLoC patterns
- **Smart Auto-loading**: Automatically loads next page when scrolling near bottom (200px threshold)
- **Item Operations**: Update or remove items without refetching entire list
- **Error Handling**: Type-safe error handling with custom error types
- **Loading State**: Built-in processing state for UI feedback
- **Refresh Support**: Pull-to-refresh and manual refresh capabilities
- **Widget Builder**: `CubitPaginatedListBuilder` for easy BLoC integration

### API

#### Core Classes

- `CursorPagination<T>` - Generic pagination state
- `PaginationResult<ItemType, CursorType, ErrorType>` - Result wrapper
- `PaginationControllerState<ItemType, CursorType, ErrorType>` - Controller state
- `FlutterPaginationController<ItemType, CursorType, ErrorType>` - ChangeNotifier controller
- `CubitPaginationController<ItemType, CursorType, ErrorType>` - BLoC/Cubit controller
- `CubitPaginatedListBuilder<ItemType, CursorType, ErrorType>` - Widget builder for BLoC

#### Methods

- `getFirst()` - Load first page
- `getNext()` - Load next page
- `refreshCurrent()` - Refresh current page
- `updateItemAt(index, item)` - Update specific item
- `removeItemAt(index)` - Remove specific item

### Dependencies

- `flutter: sdk`
- `flutter_bloc: ^8.1.0`

### Migration Guide

This is the initial release, no migration needed.
