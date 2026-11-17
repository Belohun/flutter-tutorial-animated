import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Gap between the highlighted widget and the tip of the pointer.
const double kTutorialVerticalPadding = 12;

/// Default gap between the bubble and the left/right edge of the overlay.
const double kTutorialHorizontalPadding = 24;

/// Minimal distance between the pointer and a corner of the bubble, so the
/// pointer never sits on the bubble's rounded corner.
const double kTutorialPointerToCornerMinDistance = 12;

/// Default size of the triangular pointer.
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
    required this.pointerX,
  });

  /// Lays out a step whose highlighted widget occupies [target] inside an
  /// overlay of [overlaySize], with a bubble [bubbleHeight] tall.
  ///
  /// Targets in the top half of the overlay get the bubble below them,
  /// targets in the bottom half get it above them ([flipped]).
  ///
  /// The bubble spans the overlay less [kTutorialHorizontalPadding] on each
  /// side, or [bubbleMaxWidth] when that is narrower, centred on the
  /// pointer. It overlaps the pointer by [pointerOverlap].
  factory TutorialLayout.compute({
    required Size overlaySize,
    required Rect target,
    required double bubbleHeight,
    Size pointerSize = kTutorialPointerSize,
    double pointerOverlap = 1,
    double? bubbleMaxWidth,
  }) {
    final flipped = target.center.dy >= overlaySize.height / 2;

    final pointerTop = flipped
        ? target.top - kTutorialVerticalPadding - pointerSize.height
        : target.bottom + kTutorialVerticalPadding;
    final pointerLeft = target.center.dx - pointerSize.width / 2;

    final bubbleTop = flipped
        ? pointerTop - bubbleHeight + pointerOverlap
        : pointerTop + pointerSize.height - pointerOverlap;

    final (bubbleLeft, bubbleRight) = _bubbleHorizontalInsets(
      overlayWidth: overlaySize.width,
      pointerLeft: pointerLeft,
      pointerWidth: pointerSize.width,
      maxWidth: bubbleMaxWidth,
    );

    return TutorialLayout._(
      pointerOffset: Offset(pointerLeft, pointerTop),
      flipped: flipped,
      bubbleTop: bubbleTop,
      bubbleLeft: bubbleLeft,
      bubbleRight: bubbleRight,
      pointerX: pointerLeft + pointerSize.width / 2 - bubbleLeft,
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

  /// Horizontal centre of the pointer, from the bubble's left edge.
  final double pointerX;

  /// The bubble normally keeps [kTutorialHorizontalPadding] on both sides
  /// (centred on the pointer when [maxWidth] makes it narrower). When the
  /// pointer gets closer than that to either edge, the bubble is shifted
  /// towards that edge so the pointer stays at least
  /// [kTutorialPointerToCornerMinDistance] from the bubble's corner. The
  /// bubble keeps its width.
  static (double left, double right) _bubbleHorizontalInsets({
    required double overlayWidth,
    required double pointerLeft,
    required double pointerWidth,
    required double? maxWidth,
  }) {
    final available = overlayWidth - kTutorialHorizontalPadding * 2;
    final width = math.max(0.0, math.min(available, maxWidth ?? available));

    // Centred on the pointer, then kept inside the margins.
    var left = pointerLeft + pointerWidth / 2 - width / 2;
    left = left.clamp(
      kTutorialHorizontalPadding,
      math.max(
        kTutorialHorizontalPadding,
        overlayWidth - kTutorialHorizontalPadding - width,
      ),
    );

    // Then past the margins if the pointer would sit on a corner.
    left = math.min(left, pointerLeft - kTutorialPointerToCornerMinDistance);
    left = math.max(
      left,
      pointerLeft + pointerWidth + kTutorialPointerToCornerMinDistance - width,
    );

    return (left, overlayWidth - left - width);
  }
}
