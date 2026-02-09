import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../base/callback_depth_processor.dart';
import '../base/pagination_controller.dart';
import '../base/pagination_controller_result.dart';
import '../base/pagination_controller_state.dart';
import '../base/pagination_handler.dart';
import '../base/pagination_method.dart';

/// Bloc/Cubit-based pagination controller for use with flutter_bloc.
///
/// This controller extends [Cubit] and is ideal for BLoC pattern users.
/// It emits new states automatically and integrates seamlessly with
/// BlocBuilder, BlocConsumer, etc.
///
/// Type parameters:
/// - [ItemType] - The type of items being paginated
/// - [CursorType] - The type of cursor (String, int, DateTime, etc.)
/// - [ErrorType] - The type for error information
///
/// Features:
/// - Auto-pagination when scrolling near bottom
/// - BLoC pattern state emission
/// - Item manipulation (update/remove)
/// - Processing state tracking
///
/// Example usage:
/// ```dart
/// final cubit = CubitPaginationController<Post, int, String>(
///   firstPagePointer: CursorPagination<int>(limit: 20),
///   getPageFunc: (pagination) async {
///     final posts = await api.getPosts(pagination.cursor, pagination.limit);
///     return SuccessPaginationResult(
///       itemList: posts,
///       pagination: pagination.updateCursor(posts.last.id),
///     );
///   },
/// );
/// ```
class CubitPaginationController<ItemType, CursorType, ErrorType>
    extends Cubit<PaginationControllerState<ItemType, CursorType, ErrorType>>
    with
        PaginationHandler<ItemType, CursorType, ErrorType>,
        CallbackDepthProcessor
    implements PaginationController<ItemType, CursorType, ErrorType> {
  @override
  late final ScrollController scrollController;

  @override
  final Future<PaginationResult<ItemType, CursorType, ErrorType>> Function(
    CursorPagination<CursorType>,
  )
  getPageFunc;

  @override
  final CursorPagination<CursorType> firstPagePointer;

  /// Creates a Cubit-based pagination controller.
  ///
  /// [firstPagePointer] - Initial pagination state
  /// [getPageFunc] - Function to fetch pages
  /// [scrollController] - Optional custom scroll controller
  /// [loadFirstPageOnInit] - Whether to load first page immediately (default: true)
  CubitPaginationController({
    required this.firstPagePointer,
    final ScrollController? scrollController,
    final bool loadFirstPageOnInit = true,
    required this.getPageFunc,
  }) : super(
         DataListPCState(
           lastPagination: firstPagePointer,
           itemList: [],
           isLastItems: false,
         ),
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
  Future<void> getFirst() =>
      process(() async => emit(await handlePagination(firstPagePointer, true)));

  @override
  Future<void> getNext() => process(
    () async =>
        emit(await handlePagination(state.nextPagination ?? firstPagePointer)),
  );

  @override
  Future<void> refreshCurrent() => process(
    () async => emit(
      (await handlePagination(
        state.refreshingPagination ?? firstPagePointer,
        true,
      )).copyWithPagination(state.lastPagination),
    ),
  );

  @override
  void updateItemAt(int index, ItemType newItem) =>
      process(() async => emit(state.updateItemAt(index, newItem)));

  @override
  void removeItemAt(int index) =>
      process(() async => emit(state.removeItemAt(index)));

  @override
  Future<void> close() {
    disposeDepthProcessor();
    return super.close();
  }
}
