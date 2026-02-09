import 'package:cursor_pagination/cursor_pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CursorPagination', () {
    test('creates pagination with default limit', () {
      final pagination = CursorPagination<String>();

      expect(pagination.cursor, isNull);
      expect(pagination.limit, equals(15));
    });

    test('creates pagination with custom limit', () {
      final pagination = CursorPagination<String>(limit: 20);

      expect(pagination.limit, equals(20));
    });

    test('creates pagination with cursor', () {
      final pagination = CursorPagination<String>(cursor: 'test-cursor');

      expect(pagination.cursor, equals('test-cursor'));
    });

    test('creates first page pagination', () {
      final pagination = CursorPagination<String>(
        cursor: 'old-cursor',
        limit: 10,
      );
      final firstPage = pagination.first();

      expect(firstPage.cursor, isNull);
      expect(firstPage.limit, equals(10));
    });

    test('creates first page pagination with custom limit', () {
      final pagination = CursorPagination<String>(limit: 10);
      final firstPage = pagination.first(20);

      expect(firstPage.limit, equals(20));
    });

    test('creates next page pagination', () {
      final pagination = CursorPagination<String>(
        cursor: 'cursor-1',
        limit: 10,
      );
      final nextPage = pagination.next();

      expect(nextPage.cursor, equals('cursor-1'));
      expect(nextPage.limit, equals(10));
    });

    test('returns first page when no cursor exists', () {
      final pagination = CursorPagination<String>(limit: 10);
      final nextPage = pagination.next();

      expect(nextPage.cursor, isNull);
    });

    test('updates cursor', () {
      final pagination = CursorPagination<String>(limit: 10);
      final updated = pagination.updateCursor('new-cursor');

      expect(updated.cursor, equals('new-cursor'));
      expect(updated.limit, equals(10));
    });

    test('copyWith updates cursor', () {
      final pagination = CursorPagination<String>(cursor: 'old', limit: 10);
      final updated = pagination.copyWith(cursor: 'new');

      expect(updated.cursor, equals('new'));
      expect(updated.limit, equals(10));
    });

    test('copyWith updates limit', () {
      final pagination = CursorPagination<String>(limit: 10);
      final updated = pagination.copyWith(limit: 20);

      expect(updated.limit, equals(20));
    });

    test('isLastPage returns true when items less than limit', () {
      final pagination = CursorPagination<String>(limit: 10);

      expect(pagination.isLastPage(5), isTrue);
    });

    test('isLastPage returns false when items equal to limit', () {
      final pagination = CursorPagination<String>(limit: 10);

      expect(pagination.isLastPage(10), isFalse);
    });

    test('isLastPage returns false when items more than limit', () {
      final pagination = CursorPagination<String>(limit: 10);

      expect(pagination.isLastPage(15), isFalse);
    });

    test('works with int cursor type', () {
      final pagination = CursorPagination<int>(cursor: 0, limit: 10);
      final updated = pagination.updateCursor(10);

      expect(updated.cursor, equals(10));
    });

    test('works with DateTime cursor type', () {
      final now = DateTime.now();
      final pagination = CursorPagination<DateTime>(cursor: now, limit: 10);

      expect(pagination.cursor, equals(now));
    });
  });

  group('SuccessPaginationResult', () {
    test('creates result with items and pagination', () {
      final pagination = CursorPagination<String>(
        cursor: 'cursor-1',
        limit: 10,
      );
      final result = SuccessPaginationResult<String, String, String>(
        itemList: ['item1', 'item2'],
        pagination: pagination,
      );

      expect(result.itemList, hasLength(2));
      expect(result.pagination.cursor, equals('cursor-1'));
    });

    test('isLastPage returns true when items less than limit', () {
      final pagination = CursorPagination<String>(limit: 10);
      final result = SuccessPaginationResult<String, String, String>(
        itemList: ['item1'],
        pagination: pagination,
      );

      expect(result.isLastPage, isTrue);
    });

    test('isLastPage returns false when items equal to limit', () {
      final pagination = CursorPagination<String>(limit: 2);
      final result = SuccessPaginationResult<String, String, String>(
        itemList: ['item1', 'item2'],
        pagination: pagination,
      );

      expect(result.isLastPage, isFalse);
    });
  });

  group('ErrorPaginationResult', () {
    test('creates error result with pagination', () {
      final pagination = CursorPagination<String>(limit: 10);
      final result = ErrorPaginationResult<String, String, String>(
        pagination: pagination,
        error: 'Test error',
      );

      expect(result.pagination.limit, equals(10));
      expect(result.error, equals('Test error'));
    });

    test('creates error result without error details', () {
      final pagination = CursorPagination<String>(limit: 10);
      final result = ErrorPaginationResult<String, String, String>(
        pagination: pagination,
      );

      expect(result.error, isNull);
    });
  });

  group('DataListPCState', () {
    test('creates state with items', () {
      final pagination = CursorPagination<String>(limit: 10);
      final state = DataListPCState<String, String, String>(
        itemList: ['item1', 'item2'],
        lastPagination: pagination,
        isLastItems: false,
      );

      expect(state.itemList, hasLength(2));
      expect(state.isLastItems, isFalse);
    });

    test('nextPagination returns next page', () {
      final pagination = CursorPagination<String>(
        cursor: 'cursor-1',
        limit: 10,
      );
      final state = DataListPCState<String, String, String>(
        itemList: ['item1'],
        lastPagination: pagination,
        isLastItems: false,
      );

      final nextPagination = state.nextPagination;
      expect(nextPagination.cursor, equals('cursor-1'));
    });

    test('refreshingPagination returns current pagination', () {
      final pagination = CursorPagination<String>(
        cursor: 'cursor-1',
        limit: 10,
      );
      final state = DataListPCState<String, String, String>(
        itemList: ['item1'],
        lastPagination: pagination,
        isLastItems: false,
      );

      final refreshPagination = state.refreshingPagination;
      expect(refreshPagination.cursor, equals('cursor-1'));
    });

    test('updateItemAt updates item at index', () {
      final pagination = CursorPagination<String>(limit: 10);
      final state = DataListPCState<String, String, String>(
        itemList: ['item1', 'item2'],
        lastPagination: pagination,
        isLastItems: false,
      );

      final updated = state.updateItemAt(0, 'updated-item') as DataListPCState;

      expect(updated.itemList[0], equals('updated-item'));
      expect(updated.itemList[1], equals('item2'));
    });

    test('removeItemAt removes item at index', () {
      final pagination = CursorPagination<String>(limit: 10);
      final state = DataListPCState<String, String, String>(
        itemList: ['item1', 'item2', 'item3'],
        lastPagination: pagination,
        isLastItems: false,
      );

      final updated = state.removeItemAt(1) as DataListPCState;

      expect(updated.itemList, hasLength(2));
      expect(updated.itemList[0], equals('item1'));
      expect(updated.itemList[1], equals('item3'));
    });
  });

  group('EmptyListPCState', () {
    test('creates empty state', () {
      final pagination = CursorPagination<String>(limit: 10);
      final state = EmptyListPCState<String, String, String>(
        lastPagination: pagination,
      );

      expect(state.nextPagination, isNull);
      expect(state.refreshingPagination, isNull);
    });

    test('updateItemAt returns same state', () {
      final pagination = CursorPagination<String>(limit: 10);
      final state = EmptyListPCState<String, String, String>(
        lastPagination: pagination,
      );

      final updated = state.updateItemAt(0, 'item');

      expect(updated, same(state));
    });

    test('removeItemAt returns same state', () {
      final pagination = CursorPagination<String>(limit: 10);
      final state = EmptyListPCState<String, String, String>(
        lastPagination: pagination,
      );

      final updated = state.removeItemAt(0);

      expect(updated, same(state));
    });
  });

  group('ErrorListPCState', () {
    test('creates error state with description', () {
      final pagination = CursorPagination<String>(limit: 10);
      final state = ErrorListPCState<String, String, String>(
        lastPagination: pagination,
        description: 'Test error',
      );

      expect(state.description, equals('Test error'));
      expect(state.nextPagination, isNull);
      expect(state.refreshingPagination, isNull);
    });

    test('updateItemAt returns same state', () {
      final pagination = CursorPagination<String>(limit: 10);
      final state = ErrorListPCState<String, String, String>(
        lastPagination: pagination,
      );

      final updated = state.updateItemAt(0, 'item');

      expect(updated, same(state));
    });

    test('removeItemAt returns same state', () {
      final pagination = CursorPagination<String>(limit: 10);
      final state = ErrorListPCState<String, String, String>(
        lastPagination: pagination,
      );

      final updated = state.removeItemAt(0);

      expect(updated, same(state));
    });
  });
}
