import 'package:flutter/material.dart';

/// Mixin that provides async operation depth tracking for preventing race conditions.
///
/// This mixin helps track concurrent async operations and provides a flag
/// indicating whether any operation is currently in progress. Useful for
/// disabling UI elements during pagination operations.
///
/// Features:
/// - Automatic depth counting for nested/concurrent operations
/// - Public [isProcessing] notifier for UI reactivity
/// - Proper cleanup method for disposal
///
/// Example usage:
/// ```dart
/// class MyController with CallbackDepthProcessor {
///   Future<void> loadData() => process(() async {
///     // Your async operation
///     // isProcessing.value will be true during execution
///   });
///
///   @override
///   void dispose() {
///     disposeDepthProcessor();
///     super.dispose();
///   }
/// }
/// ```
mixin CallbackDepthProcessor {
  /// Public notifier indicating if any operation is in progress.
  ///
  /// Listen to this to update UI (e.g., show loading indicators).
  final ValueNotifier<bool> isProcessing = ValueNotifier(false);

  /// Internal counter tracking operation depth.
  late final ValueNotifier<int> _processingDepth = ValueNotifier(0)
    ..addListener(_processingDepthListener);

  /// Updates [isProcessing] based on depth count.
  void _processingDepthListener() =>
      isProcessing.value = _processingDepth.value > 0;

  /// Wraps an async callback with depth tracking.
  ///
  /// Increments depth before execution, decrements after (even on error).
  /// This ensures [isProcessing] accurately reflects ongoing operations.
  ///
  /// [cb] - The async callback to execute
  /// Returns the result of [cb]
  @protected
  Future<T> process<T>(Future<T> Function() cb) async {
    _processingDepth.value += 1;
    try {
      return await cb();
    } catch (_) {
      rethrow;
    } finally {
      _processingDepth.value -= 1;
    }
  }

  /// Cleans up listeners. Call this in your dispose method.
  @protected
  void disposeDepthProcessor() {
    _processingDepth.removeListener(_processingDepthListener);
  }
}
