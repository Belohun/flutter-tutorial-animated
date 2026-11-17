import 'package:flutter/widgets.dart';

/// A single step of a [Tutorial].
///
/// Each step highlights the widget that [targetKey] is attached to and shows
/// [description] in a bubble that points at it.
@immutable
class TutorialItem {
  /// Creates a tutorial step.
  const TutorialItem({
    required this.targetKey,
    required this.description,
    this.beforeStep,
    this.animation,
    this.animationAnchorKey,
  });

  /// Key of the widget this step highlights.
  ///
  /// The widget must be laid out by the time the step is shown. Use
  /// [beforeStep] to bring it on screen first (for example by scrolling).
  final GlobalKey targetKey;

  /// Text shown in the bubble.
  final String description;

  /// Optional callback invoked, and awaited, before this step is shown.
  ///
  /// Use it to scroll the target into view with [Scrollable.ensureVisible] so
  /// the highlight lands in the right place:
  ///
  /// ```dart
  /// beforeStep: () => Scrollable.ensureVisible(
  ///   key.currentContext!,
  ///   duration: const Duration(milliseconds: 300),
  /// ),
  /// ```
  final Future<void> Function()? beforeStep;

  /// Optional decoration (a Lottie, an animated hand, ...) painted on top of
  /// the dimmed background to demonstrate the gesture this step describes.
  ///
  /// It is purely illustrative and never receives pointer events. The widget
  /// is laid out in a square as tall as the highlighted target, sitting over
  /// it and centred horizontally on [animationAnchorKey].
  final Widget? animation;

  /// Widget the [animation] is horizontally centred on.
  ///
  /// Defaults to [targetKey]. Point it at a smaller part of the target (for
  /// example a drag handle) when the gesture starts there.
  final GlobalKey? animationAnchorKey;
}
