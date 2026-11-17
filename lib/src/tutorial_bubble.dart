import 'package:flutter/widgets.dart';

import 'tutorial_item.dart';

/// Builds the bubble of a step in place of the default one. See
/// [TutorialStyle.bubbleBuilder].
typedef TutorialBubbleBuilder =
    Widget Function(BuildContext context, TutorialBubble bubble);

/// Builds the pointer between the bubble and the target in place of the
/// default triangle. [direction] is the way its tip points: [AxisDirection.up]
/// when the bubble is below the target, [AxisDirection.down] when it is
/// above. See [TutorialStyle.pointerBuilder].
typedef TutorialPointerBuilder =
    Widget Function(BuildContext context, AxisDirection direction);

/// What a [TutorialBubbleBuilder] needs to build the bubble of one step:
/// its text, where it stands in the tutorial, where the pointer meets it,
/// and the callbacks of the buttons it may show.
@immutable
class TutorialBubble {
  /// Creates the description of a step's bubble.
  const TutorialBubble({
    required this.item,
    required this.step,
    required this.stepCount,
    required this.pointerDirection,
    required this.pointerX,
    required this.next,
    required this.previous,
    required this.close,
  });

  /// The step shown. Extend [TutorialItem] to carry more than a
  /// description, such as a title or an icon.
  final TutorialItem item;

  /// Index of the step, from 0.
  final int step;

  /// Number of steps in the tutorial.
  final int stepCount;

  /// Way the pointer's tip points: [AxisDirection.up] when the pointer sits
  /// on the bubble's top edge, [AxisDirection.down] when on its bottom edge.
  final AxisDirection pointerDirection;

  /// Horizontal centre of the pointer, from the bubble's left edge.
  final double pointerX;

  /// Moves to the next step, or completes the tutorial on the last one.
  final VoidCallback next;

  /// Moves to the previous step. Does nothing on the first one.
  final VoidCallback previous;

  /// Closes the tutorial.
  final VoidCallback close;

  /// Text of the step.
  String get description => item.description;

  /// Whether this is the first step.
  bool get isFirst => step == 0;

  /// Whether this is the last step.
  bool get isLast => step == stepCount - 1;
}
