import 'pagination_method.dart';

/// Base sealed class representing the state of pagination controller.
///
/// Type parameters:
/// - [ItemType] - The type of items being paginated
/// - [CursorType] - The type of cursor for pagination
/// - [ErrorType] - The type for error information
///
/// Has three implementations:
/// - [DataListPCState] - Contains loaded data
/// - [EmptyListPCState] - Represents empty result
/// - [ErrorListPCState] - Represents error state
sealed class PaginationControllerState<ItemType, CursorType, ErrorType> {
  /// The last pagination pointer used.
  abstract final CursorPagination<CursorType> lastPagination;

  /// Creates a copy with updated pagination pointer.
  PaginationControllerState<ItemType, CursorType, ErrorType> copyWithPagination(
    CursorPagination<CursorType> pagination,
  );

  /// Gets the pagination pointer for refreshing current page.
  CursorPagination<CursorType>? get refreshingPagination;

  /// Gets the pagination pointer for loading next page.
  CursorPagination<CursorType>? get nextPagination;

  /// Updates an item at specified index. Returns new state.
  PaginationControllerState<ItemType, CursorType, ErrorType> updateItemAt(
    int index,
    ItemType newItem,
  );

  /// Removes an item at specified index. Returns new state.
  PaginationControllerState<ItemType, CursorType, ErrorType> removeItemAt(
    int index,
  );
}

/// State containing a list of loaded items.
///
/// This is the primary state when data has been successfully loaded.
class DataListPCState<ItemType, CursorType, ErrorType>
    implements PaginationControllerState<ItemType, CursorType, ErrorType> {
  /// The list of items that have been loaded.
  final List<ItemType> itemList;

  @override
  final CursorPagination<CursorType> lastPagination;

  /// Whether this is the last page (no more items to load).
  final bool isLastItems;

  const DataListPCState({
    required this.itemList,
    required this.lastPagination,
    required this.isLastItems,
  });

  @override
  CursorPagination<CursorType> get nextPagination => lastPagination.next();

  @override
  CursorPagination<CursorType> get refreshingPagination =>
      lastPagination.copyWith();

  @override
  DataListPCState<ItemType, CursorType, ErrorType> copyWithPagination(
    CursorPagination<CursorType> pagination,
  ) => DataListPCState(
    itemList: itemList,
    lastPagination: pagination,
    isLastItems: isLastItems,
  );

  @override
  PaginationControllerState<ItemType, CursorType, ErrorType> removeItemAt(
    int index,
  ) => DataListPCState(
    itemList: [...itemList]..removeAt(index),
    lastPagination: lastPagination,
    isLastItems: isLastItems,
  );

  @override
  PaginationControllerState<ItemType, CursorType, ErrorType> updateItemAt(
    int index,
    ItemType newItem,
  ) => DataListPCState(
    itemList: [...itemList]..[index] = newItem,
    lastPagination: lastPagination,
    isLastItems: isLastItems,
  );
}

/// State representing an empty result (no items found).
///
/// This occurs when the initial fetch returns no items.
class EmptyListPCState<ItemType, CursorType, ErrorType>
    implements PaginationControllerState<ItemType, CursorType, ErrorType> {
  @override
  final CursorPagination<CursorType> lastPagination;

  const EmptyListPCState({required this.lastPagination});

  @override
  EmptyListPCState<ItemType, CursorType, ErrorType> copyWithPagination(
    CursorPagination<CursorType> pagination,
  ) {
    return EmptyListPCState(lastPagination: pagination);
  }

  @override
  CursorPagination<CursorType>? get nextPagination => null;

  @override
  CursorPagination<CursorType>? get refreshingPagination => null;

  @override
  PaginationControllerState<ItemType, CursorType, ErrorType> removeItemAt(
    int index,
  ) => this;

  @override
  PaginationControllerState<ItemType, CursorType, ErrorType> updateItemAt(
    int index,
    ItemType newItem,
  ) => this;
}

/// State representing an error during pagination.
///
/// Contains optional error details of type [ErrorType].
class ErrorListPCState<ItemType, CursorType, ErrorType>
    implements PaginationControllerState<ItemType, CursorType, ErrorType> {
  @override
  final CursorPagination<CursorType> lastPagination;

  /// Optional error description or details.
  final ErrorType? description;

  ErrorListPCState({required this.lastPagination, this.description});

  @override
  ErrorListPCState<ItemType, CursorType, ErrorType> copyWithPagination(
    CursorPagination<CursorType> pagination,
  ) {
    return ErrorListPCState(
      description: description,
      lastPagination: pagination,
    );
  }

  @override
  CursorPagination<CursorType>? get nextPagination => null;

  @override
  CursorPagination<CursorType>? get refreshingPagination => null;

  @override
  PaginationControllerState<ItemType, CursorType, ErrorType> removeItemAt(
    int index,
  ) => this;

  @override
  PaginationControllerState<ItemType, CursorType, ErrorType> updateItemAt(
    int index,
    ItemType newItem,
  ) => this;
}
