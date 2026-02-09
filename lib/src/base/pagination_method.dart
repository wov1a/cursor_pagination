/// A generic cursor-based pagination class that supports flexible cursor types.
///
/// This class encapsulates the state needed for cursor-based pagination,
/// including a generic cursor value and a limit for items per page.
///
/// The cursor can be any type [T] (String, int, DateTime, etc.), providing
/// maximum flexibility for different pagination strategies.
///
/// Example usage:
/// ```dart
/// // String-based cursor
/// final pagination = CursorPagination<String>(cursor: 'user_123', limit: 20);
///
/// // DateTime-based cursor
/// final timePagination = CursorPagination<DateTime>(
///   cursor: DateTime.now(),
///   limit: 10,
/// );
///
/// // Integer-based cursor
/// final idPagination = CursorPagination<int>(cursor: 42, limit: 15);
/// ```
class CursorPagination<T> {
  /// The cursor value used for pagination. Can be null for the first page.
  final T? cursor;

  /// The maximum number of items to fetch per page.
  final int limit;

  /// Creates a cursor pagination instance.
  ///
  /// [cursor] - The cursor value (can be null for first page)
  /// [limit] - Maximum items per page (default: 15)
  const CursorPagination({this.cursor, this.limit = 15});

  /// Creates a pagination instance for the first page.
  ///
  /// [limit] - Optional custom limit, otherwise uses current limit
  CursorPagination<T> first([int? limit]) =>
      CursorPagination<T>(limit: limit ?? this.limit);

  /// Creates a pagination instance for the next page using current cursor.
  ///
  /// [limit] - Optional custom limit, otherwise uses current limit
  ///
  /// If no cursor exists, returns first page instead.
  CursorPagination<T> next([int? limit]) {
    if (cursor == null) return first(limit);
    return CursorPagination<T>(cursor: cursor, limit: limit ?? this.limit);
  }

  /// Updates the cursor with a new value.
  ///
  /// [newCursor] - The new cursor value to use
  CursorPagination<T> updateCursor(T newCursor) {
    return CursorPagination<T>(cursor: newCursor, limit: limit);
  }

  /// Creates a copy of this pagination with the current cursor.
  ///
  /// Useful for refreshing the current page.
  CursorPagination<T> copyWith({T? cursor, int? limit}) => CursorPagination<T>(
    cursor: cursor ?? this.cursor,
    limit: limit ?? this.limit,
  );

  /// Determines if this is the last page based on item count.
  ///
  /// Returns true if [elementCount] is less than the [limit],
  /// indicating no more items are available.
  bool isLastPage(int elementCount) => elementCount < limit;
}
