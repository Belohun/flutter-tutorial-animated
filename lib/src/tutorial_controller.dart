import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tutorial.dart';

/// Drives the step index of a running [Tutorial].
class TutorialController {
  /// Creates a controller for [stepCount] steps.
  TutorialController({required this.stepCount, required this.prepareStep})
    : assert(stepCount > 0, 'A tutorial needs at least one step');

  /// Number of steps.
  final int stepCount;

  /// Awaited before a step is shown. Resolves to `false` when the step cannot
  /// be shown, which finishes the tutorial with
  /// [TutorialResult.targetNotFound].
  final Future<bool> Function(int step) prepareStep;

  final ValueNotifier<int?> _index = ValueNotifier<int?>(null);
  final Completer<TutorialResult> _completer = Completer<TutorialResult>();
  bool _transitioning = false;

  /// Index of the step on screen, or `null` before the first one is shown.
  ValueListenable<int?> get index => _index;

  /// Completes once the tutorial is finished.
  Future<TutorialResult> get result => _completer.future;

  /// Whether the tutorial has finished.
  bool get isFinished => _completer.isCompleted;

  /// Called once, when the tutorial finishes.
  VoidCallback? onFinish;

  /// Shows the first step.
  Future<void> start() => _goTo(0);

  /// Moves to the next step, or completes the tutorial on the last one.
  Future<void> next() async {
    final current = _index.value;
    if (current == null || _transitioning || isFinished) return;

    if (current + 1 >= stepCount) {
      finish(TutorialResult.completed);
      return;
    }

    await _goTo(current + 1);
  }

  /// Moves to the previous step. Does nothing on the first one.
  Future<void> previous() async {
    final current = _index.value;
    if (current == null || current == 0 || _transitioning || isFinished) {
      return;
    }

    await _goTo(current - 1);
  }

  /// Finishes the tutorial with [result]. Later calls are ignored.
  void finish(TutorialResult result) {
    if (isFinished) return;
    _completer.complete(result);
    onFinish?.call();
  }

  Future<void> _goTo(int step) async {
    // Taps while a beforeStep callback (e.g. a scroll) is running would
    // otherwise skip steps.
    _transitioning = true;
    final bool ready;
    try {
      ready = await prepareStep(step);
    } finally {
      _transitioning = false;
    }

    if (isFinished) return;
    if (!ready) {
      finish(TutorialResult.targetNotFound);
      return;
    }
    _index.value = step;
  }

  /// Releases the resources held by the controller.
  void dispose() => _index.dispose();
}
