import 'package:flutter/foundation.dart';

import 'pagination_controller.dart';
import 'pagination_controller_result.dart';
import 'pagination_controller_state.dart';
import 'pagination_method.dart';

/// Mixin that provides core pagination handling logic.
///
/// This mixin implements the business logic for processing pagination requests
/// and managing state transitions between different pagination states.
///
/// Type parameters:
/// - [ItemType] - The type of items being paginated
/// - [CursorType] - The type of cursor for pagination
/// - [ErrorType] - The type for error information
mixin PaginationHandler<ItemType, CursorType, ErrorType>
    implements PaginationController<ItemType, CursorType, ErrorType> {
  /// Core logic for handling pagination requests.
  ///
  /// Processes the pagination request and returns the new state based on:
  /// - Current state (Data, Empty, or Error)
  /// - Result from [getPageFunc] (Success or Error)
  /// - Whether to replace or append items ([replaceOldList])
  ///
  /// [pagination] - The pagination pointer to use for fetching
  /// [replaceOldList] - If true, replaces existing items; if false, appends (default: false)
  @protected
  Future<PaginationControllerState<ItemType, CursorType, ErrorType>>
  handlePagination(
    CursorPagination<CursorType> pagination, [
    bool replaceOldList = false,
  ]) async {
    switch (state) {
      case DataListPCState<ItemType, CursorType, ErrorType>(:final itemList):
        final getPageResult = await getPageFunc(pagination);

        switch (getPageResult) {
          case SuccessPaginationResult(
            itemList: final newItemList,
            pagination: final newPagination,
            :final isLastPage,
          ):
            if (newItemList.isEmpty) {
              // Empty response on first page = truly empty
              if (pagination.cursor == null) {
                return EmptyListPCState<ItemType, CursorType, ErrorType>(
                  lastPagination: newPagination,
                );
              } else {
                // Empty response on subsequent page = reached end
                return DataListPCState<ItemType, CursorType, ErrorType>(
                  itemList: itemList,
                  lastPagination: newPagination,
                  isLastItems: true,
                );
              }
            }

            return DataListPCState<ItemType, CursorType, ErrorType>(
              itemList: replaceOldList
                  ? newItemList
                  : [...itemList, ...newItemList],
              lastPagination: newPagination,
              isLastItems: isLastPage,
            );

          case ErrorPaginationResult<ItemType, CursorType, ErrorType>(
            :final pagination,
            :final error,
          ):
            return ErrorListPCState<ItemType, CursorType, ErrorType>(
              lastPagination: pagination,
              description: error,
            );
        }

      case EmptyListPCState<ItemType, CursorType, ErrorType>():
      case ErrorListPCState<ItemType, CursorType, ErrorType>():
        final getPageResult = await getPageFunc(pagination);

        switch (getPageResult) {
          case SuccessPaginationResult(
            itemList: final newItemList,
            pagination: final newPagination,
            :final isLastPage,
          ):
            if (newItemList.isEmpty) {
              if (pagination.cursor == null) {
                return EmptyListPCState<ItemType, CursorType, ErrorType>(
                  lastPagination: newPagination,
                );
              } else {
                return DataListPCState<ItemType, CursorType, ErrorType>(
                  itemList: [],
                  lastPagination: newPagination,
                  isLastItems: true,
                );
              }
            }

            return DataListPCState<ItemType, CursorType, ErrorType>(
              itemList: newItemList,
              lastPagination: newPagination,
              isLastItems: isLastPage,
            );

          case ErrorPaginationResult<ItemType, CursorType, ErrorType>(
            :final pagination,
            :final error,
          ):
            return ErrorListPCState<ItemType, CursorType, ErrorType>(
              lastPagination: pagination,
              description: error,
            );
        }
    }
  }
}
