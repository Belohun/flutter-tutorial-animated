import 'package:flutter/widgets.dart';

import 'tutorial_barrier.dart';

/// A single step of a [Tutorial].
///
/// Each step highlights its target and shows [description] in a bubble that
/// points at it. The target is either the widget [targetKey] is attached to,
/// or the area [targetRect] reports, for things that are not widgets (a
/// sprite in a game, a region of a canvas, ...).
@immutable
class TutorialItem {
  /// Creates a tutorial step. Give it exactly one of [targetKey] and
  /// [targetRect].
  const TutorialItem({
    required this.description,
    this.targetKey,
    this.targetRect,
    this.barrier,
    this.nextOnTargetTouch = false,
    this.beforeStep,
    this.animation,
    this.animationAnchorKey,
  }) : assert(
         (targetKey == null) != (targetRect == null),
         'Give a TutorialItem either a targetKey or a targetRect',
       );

  /// Key of the widget this step highlights.
  ///
  /// The widget must be laid out by the time the step is shown. Use
  /// [beforeStep] to bring it on screen first (for example by scrolling).
  final GlobalKey? targetKey;

  /// Reports the area this step highlights, in global (screen) coordinates,
  /// or `null` while it is not on screen.
  ///
  /// Use it for targets that are not widgets, such as a sprite in a game.
  /// It is called on every frame while the step is shown, so the highlight,
  /// the pointer and the bubble follow a target that moves.
  final Rect? Function()? targetRect;

  /// What the dimmed background does with taps during this step. Defaults
  /// to [Tutorial.barrier].
  final TutorialBarrier? barrier;

  /// Whether touching the highlight moves the tutorial on, as Next does,
  /// or completes it on the last step.
  ///
  /// It reacts as the finger lands, so the start of a drag counts as much
  /// as a tap. The touch still reaches the app below wherever the
  /// [barrier] lets taps through, so the user does what the step asks and
  /// the bubble gets out of the way in one go.
  final bool nextOnTargetTouch;

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
  /// Defaults to the target. Point it at a smaller part of the target (for
  /// example a drag handle) when the gesture starts there.
  final GlobalKey? animationAnchorKey;
}
