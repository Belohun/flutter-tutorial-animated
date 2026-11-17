import 'package:flutter/widgets.dart';

/// Gap between the highlighted widget and the tip of the pointer.
const double kTutorialVerticalPadding = 12;

/// Default gap between the bubble and the left/right edge of the overlay.
const double kTutorialHorizontalPadding = 24;

/// Minimal distance between the pointer and a corner of the bubble, so the
/// pointer never sits on the bubble's rounded corner.
const double kTutorialPointerToCornerMinDistance = 12;

/// Size of the triangular pointer.
const Size kTutorialPointerSize = Size(32, 28);

/// Positions of the pointer and the description bubble for one step.
///
/// Pure geometry, kept apart from the widgets so it can be unit tested.
@immutable
class TutorialLayout {
  const TutorialLayout._({
    required this.pointerOffset,
    required this.flipped,
    required this.bubbleTop,
    required this.bubbleLeft,
    required this.bubbleRight,
  });

  /// Lays out a step whose highlighted widget occupies [target] inside an
  /// overlay of [overlaySize], with a bubble [bubbleHeight] tall.
  ///
  /// Targets in the top half of the overlay get the bubble below them,
  /// targets in the bottom half get it above them ([flipped]).
  factory TutorialLayout.compute({
    required Size overlaySize,
    required Rect target,
    required double bubbleHeight,
  }) {
    final flipped = target.center.dy >= overlaySize.height / 2;

    final pointerTop = flipped
        ? target.top - kTutorialVerticalPadding - kTutorialPointerSize.height
        : target.bottom + kTutorialVerticalPadding;
    final pointerLeft = target.center.dx - kTutorialPointerSize.width / 2;

    // The bubble overlaps the pointer by a pixel so no hairline shows between
    // them.
    final bubbleTop = flipped
        ? pointerTop - bubbleHeight + 1
        : pointerTop + kTutorialPointerSize.height - 1;

    final (bubbleLeft, bubbleRight) = _bubbleHorizontalInsets(
      overlayWidth: overlaySize.width,
      pointerLeft: pointerLeft,
    );

    return TutorialLayout._(
      pointerOffset: Offset(pointerLeft, pointerTop),
      flipped: flipped,
      bubbleTop: bubbleTop,
      bubbleLeft: bubbleLeft,
      bubbleRight: bubbleRight,
    );
  }

  /// Top-left corner of the pointer.
  final Offset pointerOffset;

  /// Whether the bubble sits above the target, with the pointer facing down.
  final bool flipped;

  /// Distance from the top of the overlay to the top of the bubble.
  final double bubbleTop;

  /// Distance from the left edge of the overlay to the bubble.
  final double bubbleLeft;

  /// Distance from the right edge of the overlay to the bubble.
  final double bubbleRight;

  /// The bubble normally keeps [kTutorialHorizontalPadding] on both sides.
  /// When the pointer gets closer than that to either edge, the bubble is
  /// shifted towards that edge so the pointer stays at least
  /// [kTutorialPointerToCornerMinDistance] from the bubble's corner. The sum of
  /// both insets stays constant, so the bubble keeps its width.
  static (double left, double right) _bubbleHorizontalInsets({
    required double overlayWidth,
    required double pointerLeft,
  }) {
    const threshold =
        kTutorialHorizontalPadding + kTutorialPointerToCornerMinDistance;
    const totalInset = kTutorialHorizontalPadding * 2;

    if (pointerLeft <= threshold) {
      final left = pointerLeft - kTutorialPointerToCornerMinDistance;
      return (left, totalInset - left);
    }

    final pointerRight =
        overlayWidth - pointerLeft - kTutorialPointerSize.width;
    if (pointerRight <= threshold) {
      final right = pointerRight - kTutorialPointerToCornerMinDistance;
      return (totalInset - right, right);
    }

    return (kTutorialHorizontalPadding, kTutorialHorizontalPadding);
  }
}
