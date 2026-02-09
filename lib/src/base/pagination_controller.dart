import 'dart:async';

import 'package:flutter/material.dart';

import 'pagination_controller_result.dart';
import 'pagination_controller_state.dart';
import 'pagination_method.dart';

/// An abstract interface that defines a generic pagination controller.
///
/// This controller manages cursor-based pagination with full type flexibility:
/// - [ItemType] - The type of items being paginated
/// - [CursorType] - The type of cursor used for pagination (String, int, DateTime, etc.)
/// - [ErrorType] - Custom error type for better error handling
///
/// Example usage:
/// ```dart
/// class MyController implements PaginationController<User, String, ApiError> {
///   // Implementation
/// }
/// ```
abstract interface class PaginationController<ItemType, CursorType, ErrorType> {
  /// ScrollController used to track scrolling events for auto-loading.
  abstract final ScrollController scrollController;

  /// Function that fetches the next page of data.
  ///
  /// Takes a [CursorPagination] and returns [PaginationResult] with items or error.
  abstract final Future<PaginationResult<ItemType, CursorType, ErrorType>>
  Function(CursorPagination<CursorType> pagination)
  getPageFunc;

  /// The initial pagination pointer for the first page.
  abstract final CursorPagination<CursorType> firstPagePointer;

  /// Notifier indicating if a pagination operation is in progress.
  abstract final ValueNotifier<bool> isProcessing;

  /// Current state of the pagination controller.
  PaginationControllerState<ItemType, CursorType, ErrorType> get state;

  /// Fetch the first page, replacing any existing data.
  Future<void> getFirst();

  /// Fetch the next page and append to existing data.
  Future<void> getNext();

  /// Refresh the current page, replacing existing data.
  Future<void> refreshCurrent();

  /// Updates a specific item at the given [index].
  ///
  /// Only works when state is [DataListPCState].
  void updateItemAt(int index, ItemType newItem);

  /// Removes an item at the given [index].
  ///
  /// Only works when state is [DataListPCState].
  void removeItemAt(int index);
}
