import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../base/callback_depth_processor.dart';
import '../base/pagination_controller.dart';
import '../base/pagination_controller_result.dart';
import '../base/pagination_controller_state.dart';
import '../base/pagination_handler.dart';
import '../base/pagination_method.dart';

/// Flutter pagination controller using [ChangeNotifier] for state management.
///
/// This controller is ideal for use with standard Flutter state management
/// (Provider, GetX, etc.). It extends [ChangeNotifier] and automatically
/// triggers rebuilds when state changes.
///
/// Type parameters:
/// - [ItemType] - The type of items being paginated
/// - [CursorType] - The type of cursor (String, int, DateTime, etc.)
/// - [ErrorType] - The type for error information
///
/// Features:
/// - Auto-pagination when scrolling near bottom (200px threshold)
/// - Manual refresh and navigation methods
/// - Item manipulation (update/remove)
/// - Processing state tracking
///
/// Example usage:
/// ```dart
/// final controller = FlutterPaginationController<User, String, ApiError>(
///   firstPagePointer: CursorPagination<String>(limit: 20),
///   getPageFunc: (pagination) async {
///     final response = await api.getUsers(pagination);
///     return SuccessPaginationResult(
///       itemList: response.users,
///       pagination: pagination.updateCursor(response.nextCursor),
///     );
///   },
/// );
/// ```
class FlutterPaginationController<ItemType, CursorType, ErrorType>
    with
        ChangeNotifier,
        PaginationHandler<ItemType, CursorType, ErrorType>,
        CallbackDepthProcessor
    implements PaginationController<ItemType, CursorType, ErrorType> {
  @override
  late final ScrollController scrollController;

  PaginationControllerState<ItemType, CursorType, ErrorType> _state;

  @override
  PaginationControllerState<ItemType, CursorType, ErrorType> get state =>
      _state;

  @override
  final CursorPagination<CursorType> firstPagePointer;

  @override
  final Future<PaginationResult<ItemType, CursorType, ErrorType>> Function(
    CursorPagination<CursorType>,
  )
  getPageFunc;

  /// Creates a Flutter pagination controller.
  ///
  /// [firstPagePointer] - Initial pagination state
  /// [getPageFunc] - Function to fetch pages
  /// [scrollController] - Optional custom scroll controller
  /// [loadFirstPageOnInit] - Whether to load first page immediately (default: true)
  /// [initialState] - Optional custom initial state
  FlutterPaginationController({
    required this.firstPagePointer,
    final ScrollController? scrollController,
    final bool loadFirstPageOnInit = true,
    final PaginationControllerState<ItemType, CursorType, ErrorType>?
    initialState,
    required this.getPageFunc,
  }) : _state =
           initialState ??
           DataListPCState(
             itemList: [],
             lastPagination: firstPagePointer,
             isLastItems: false,
           ) {
    this.scrollController = scrollController ?? ScrollController();
    this.scrollController.addListener(_scrollListener);

    if (loadFirstPageOnInit) getFirst();
  }

  bool _hasAlreadyInvokedByScrollController = false;

  /// Scroll listener for auto-loading next page.
  void _scrollListener() async {
    if (_hasAlreadyInvokedByScrollController) return;
    if (scrollController.position.extentAfter < 200 &&
        scrollController.position.userScrollDirection ==
            ScrollDirection.reverse) {
      switch (state) {
        case DataListPCState<ItemType, CursorType, ErrorType>(
          isLastItems: final isLastPage,
        ):
          if (!isLastPage) {
            _hasAlreadyInvokedByScrollController = true;
            await getNext();
            _hasAlreadyInvokedByScrollController = false;
          }
          break;
        case EmptyListPCState<ItemType, CursorType, ErrorType>():
        case ErrorListPCState<ItemType, CursorType, ErrorType>():
          break;
      }
    }
  }

  @override
  Future<void> getFirst() => process(() async {
    _state = await handlePagination(firstPagePointer, true);
    notifyListeners();
  });

  @override
  Future<void> getNext() => process(() async {
    _state = await handlePagination(_state.nextPagination ?? firstPagePointer);
    notifyListeners();
  });

  @override
  Future<void> refreshCurrent() => process(() async {
    _state = (await handlePagination(
      _state.refreshingPagination ?? firstPagePointer,
      true,
    )).copyWithPagination(_state.lastPagination);
    notifyListeners();
  });

  @override
  void updateItemAt(int index, ItemType newItem) => process(() async {
    _state = _state.updateItemAt(index, newItem);
    notifyListeners();
  });

  @override
  void removeItemAt(int index) => process(() async {
    _state = _state.removeItemAt(index);
    notifyListeners();
  });

  @override
  void dispose() {
    disposeDepthProcessor();
    super.dispose();
  }
}
