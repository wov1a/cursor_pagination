import 'pagination_method.dart';

/// Base sealed class for pagination operation results.
///
/// Type parameters:
/// - [ItemType] - The type of items in the result
/// - [CursorType] - The type of cursor used for pagination
/// - [ErrorType] - The type of error information
///
/// This sealed class has two implementations:
/// - [SuccessPaginationResult] - Contains fetched items
/// - [ErrorPaginationResult] - Contains error information
sealed class PaginationResult<ItemType, CursorType, ErrorType> {}

/// Successful pagination result containing items and updated pagination state.
///
/// Example:
/// ```dart
/// return SuccessPaginationResult(
///   itemList: users,
///   pagination: updatedPagination,
/// );
/// ```
class SuccessPaginationResult<ItemType, CursorType, ErrorType>
    implements PaginationResult<ItemType, CursorType, ErrorType> {
  /// The list of fetched items for this page.
  final List<ItemType> itemList;

  /// Updated pagination state after fetching.
  final CursorPagination<CursorType> pagination;

  const SuccessPaginationResult({
    required this.itemList,
    required this.pagination,
  });

  /// Determines if this is the last page based on item count.
  bool get isLastPage => pagination.isLastPage(itemList.length);
}

/// Error pagination result containing error information.
///
/// Example:
/// ```dart
/// return ErrorPaginationResult(
///   pagination: currentPagination,
///   error: ApiError(message: 'Network timeout'),
/// );
/// ```
class ErrorPaginationResult<ItemType, CursorType, ErrorType>
    implements PaginationResult<ItemType, CursorType, ErrorType> {
  /// The pagination state at the time of error.
  final CursorPagination<CursorType> pagination;

  /// Optional error details.
  final ErrorType? error;

  const ErrorPaginationResult({required this.pagination, this.error});
}
