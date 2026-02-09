import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../base/pagination_controller_state.dart';
import '../controller/cubit_pagination_controller.dart';

/// Widget for building paginated lists using [CubitPaginationController].
///
/// This widget automatically rebuilds when pagination state changes and
/// provides separate builders for each state: data, empty, and error.
///
/// Type parameters must match your controller:
/// - [ItemType] - The type of items
/// - [CursorType] - The type of cursor
/// - [ErrorType] - The type of error information
///
/// Example usage:
/// ```dart
/// CubitPaginatedListBuilder<User, String, ApiError>(
///   dataBuilder: (context, dataState, isProcessing) {
///     return ListView.builder(
///       controller: context.read<CubitPaginationController>().scrollController,
///       itemCount: dataState.itemList.length + (dataState.isLastItems ? 0 : 1),
///       itemBuilder: (context, index) {
///         if (index >= dataState.itemList.length) {
///           return CircularProgressIndicator(); // Loading indicator
///         }
///         return UserTile(user: dataState.itemList[index]);
///       },
///     );
///   },
///   emptyBuilder: (context, emptyState, isProcessing) {
///     return Center(child: Text('No users found'));
///   },
///   errorBuilder: (context, errorState, isProcessing) {
///     return Center(child: Text('Error: ${errorState.description}'));
///   },
/// )
/// ```
class CubitPaginatedListBuilder<ItemType, CursorType, ErrorType>
    extends StatelessWidget {
  /// Optional controller. If not provided, will be read from context.
  final CubitPaginationController<ItemType, CursorType, ErrorType>? controller;

  /// Builder for data state - called when items are loaded.
  ///
  /// Parameters:
  /// - [context] - Build context
  /// - [dataState] - Current data state with item list
  /// - [isProcessing] - Whether pagination operation is in progress
  final Widget Function(
    BuildContext context,
    DataListPCState<ItemType, CursorType, ErrorType> dataState,
    bool isProcessing,
  )
  dataBuilder;

  /// Builder for empty state - called when no items are found.
  final Widget Function(
    BuildContext context,
    EmptyListPCState<ItemType, CursorType, ErrorType> emptyState,
    bool isProcessing,
  )
  emptyBuilder;

  /// Builder for error state - called when an error occurs.
  final Widget Function(
    BuildContext context,
    ErrorListPCState<ItemType, CursorType, ErrorType> errorState,
    bool isProcessing,
  )
  errorBuilder;

  const CubitPaginatedListBuilder({
    super.key,
    this.controller,
    required this.dataBuilder,
    required this.emptyBuilder,
    required this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _CubitPaginatedListBuilder(
      controller: controller,
      builder: (context, state, isProcessing) => switch (state) {
        DataListPCState<ItemType, CursorType, ErrorType>() => dataBuilder(
          context,
          state,
          isProcessing,
        ),
        EmptyListPCState<ItemType, CursorType, ErrorType>() => emptyBuilder(
          context,
          state,
          isProcessing,
        ),
        ErrorListPCState<ItemType, CursorType, ErrorType>() => errorBuilder(
          context,
          state,
          isProcessing,
        ),
      },
    );
  }
}

/// Internal widget that listens to state and processing changes.
class _CubitPaginatedListBuilder<ItemType, CursorType, ErrorType>
    extends StatelessWidget {
  final CubitPaginationController<ItemType, CursorType, ErrorType>? controller;

  /// General builder that receives state and isProcessing flag
  final Widget Function(
    BuildContext context,
    PaginationControllerState<ItemType, CursorType, ErrorType> state,
    bool isProcessing,
  )
  builder;

  const _CubitPaginatedListBuilder({
    super.key,
    this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final controller =
        this.controller ??
        context
            .read<CubitPaginationController<ItemType, CursorType, ErrorType>>();

    return ValueListenableBuilder<bool>(
      valueListenable: controller.isProcessing,
      builder: (context, isProcessing, _) {
        return BlocBuilder<
          CubitPaginationController<ItemType, CursorType, ErrorType>,
          PaginationControllerState<ItemType, CursorType, ErrorType>
        >(
          bloc: controller,
          builder: (context, state) {
            return builder(context, state, isProcessing);
          },
        );
      },
    );
  }
}
