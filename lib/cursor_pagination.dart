/// A flexible cursor-based pagination library for Flutter.
///
/// This library provides a complete solution for implementing cursor-based
/// pagination in Flutter applications with support for:
/// - Multiple state management approaches (ChangeNotifier, BLoC/Cubit)
/// - Flexible cursor types (String, int, DateTime, custom types)
/// - Auto-loading on scroll
/// - Error handling
/// - Item manipulation
///
/// ## Quick Start
///
/// 1. Create a pagination controller:
/// ```dart
/// final controller = FlutterPaginationController<User, String, String>(
///   firstPagePointer: CursorPagination<String>(limit: 20),
///   getPageFunc: (pagination) async {
///     // Fetch data from your API
///     final response = await api.getUsers(
///       cursor: pagination.cursor,
///       limit: pagination.limit,
///     );
///
///     return SuccessPaginationResult(
///       itemList: response.users,
///       pagination: pagination.updateCursor(response.nextCursor),
///     );
///   },
/// );
/// ```
///
/// 2. Use with ListView:
/// ```dart
/// ListView.builder(
///   controller: controller.scrollController,
///   itemCount: state.itemList.length,
///   itemBuilder: (context, index) => UserTile(state.itemList[index]),
/// );
/// ```
///
/// ## Controllers
///
/// - [FlutterPaginationController] - For ChangeNotifier-based state management
/// - [CubitPaginationController] - For BLoC/Cubit pattern
///
/// ## Core Classes
///
/// - [CursorPagination] - Pagination state with cursor and limit
/// - [PaginationResult] - Result wrapper (Success or Error)
/// - [PaginationControllerState] - Controller state (Data, Empty, or Error)
library cursor_pagination;

// Core base classes
export 'src/base/pagination_method.dart';
export 'src/base/pagination_controller.dart';
export 'src/base/pagination_controller_result.dart';
export 'src/base/pagination_controller_state.dart';
export 'src/base/pagination_handler.dart';
export 'src/base/callback_depth_processor.dart';

// Controllers
export 'src/controller/flutter_pagination_controller.dart';
export 'src/controller/cubit_pagination_controller.dart';

// Widgets
export 'src/widget/cubit_pagination_list_builder.dart';
