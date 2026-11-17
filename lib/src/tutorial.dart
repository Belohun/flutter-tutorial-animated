import 'package:flutter/widgets.dart';

import 'tutorial_button.dart';
import 'tutorial_controller.dart';
import 'tutorial_item.dart';
import 'tutorial_layout.dart';
import 'tutorial_painters.dart';
import 'tutorial_style.dart';

/// How a [Tutorial] ended.
enum TutorialResult {
  /// The user went through every step.
  completed,

  /// The user closed the tutorial before the last step.
  closed,

  /// A step's target was not laid out within [Tutorial.targetTimeout], or the
  /// overlay went away before the tutorial could be shown. The tutorial ends
  /// at that step.
  targetNotFound,
}

/// A step-by-step tutorial that highlights widgets one at a time.
///
/// Each [TutorialItem] dims the screen around its target, points at it with a
/// bubble holding the description, and offers buttons to go back, forward or
/// close. Moving between steps animates the cut-out, the pointer and the
/// bubble.
///
/// ```dart
/// final result = await Tutorial(
///   items: [
///     TutorialItem(targetKey: _searchKey, description: 'Search here'),
///     TutorialItem(targetKey: _addKey, description: 'Add a new item'),
///   ],
/// ).show(context);
/// ```
@immutable
class Tutorial {
  /// Creates a tutorial with the given steps. [items] must not be empty.
  const Tutorial({
    required this.items,
    this.style = const TutorialStyle(),
    this.useRootOverlay = false,
    this.targetTimeout = const Duration(seconds: 10),
  });

  /// The steps, in order.
  final List<TutorialItem> items;

  /// Visual configuration.
  final TutorialStyle style;

  /// Whether to show the tutorial in the root [Overlay] instead of the
  /// nearest one. Set it to cover widgets outside the nearest [Navigator],
  /// such as a bottom navigation bar around a nested navigator.
  final bool useRootOverlay;

  /// How long to wait for a step's target to be laid out (after its
  /// [TutorialItem.beforeStep]) before giving up with
  /// [TutorialResult.targetNotFound].
  final Duration targetTimeout;

  static const Duration _layoutPollInterval = Duration(milliseconds: 50);

  /// Shows the tutorial over the [Overlay] of [context] and completes when it
  /// ends.
  Future<TutorialResult> show(BuildContext context) async {
    assert(items.isNotEmpty, 'A tutorial needs at least one item');

    final overlayState = Overlay.of(context, rootOverlay: useRootOverlay);
    final controller = TutorialController(
      stepCount: items.length,
      prepareStep: _prepareStep,
    );

    await controller.start();
    if (!controller.isFinished && !overlayState.mounted) {
      controller.finish(TutorialResult.targetNotFound);
    }
    if (controller.isFinished) {
      controller.dispose();
      return controller.result;
    }

    final entry = OverlayEntry(
      builder: (context) => _TutorialOverlay(
        tutorial: this,
        controller: controller,
        overlayState: overlayState,
      ),
    );
    controller.onFinish = () {
      entry
        ..remove()
        ..dispose();
    };
    overlayState.insert(entry);

    return controller.result;
  }

  Future<bool> _prepareStep(int step) async {
    final item = items[step];
    await item.beforeStep?.call();
    return _waitForLayout(item.targetKey);
  }

  /// Polls a fixed number of times rather than against a clock, so the
  /// timeout also holds under the fake clock of widget tests.
  Future<bool> _waitForLayout(GlobalKey key) async {
    final attempts =
        targetTimeout.inMicroseconds ~/ _layoutPollInterval.inMicroseconds;

    for (var attempt = 0; !_isLaidOut(key); attempt++) {
      if (attempt >= attempts) return false;
      await Future<void>.delayed(_layoutPollInterval);
    }
    return true;
  }

  static bool _isLaidOut(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    return renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize &&
        renderObject.size.isFinite;
  }
}

/// Bounds of the widget behind [key] in [ancestor]'s coordinates, or `null`
/// when that widget is not laid out right now.
Rect? _rectOf(GlobalKey key, RenderBox? ancestor) {
  final box = key.currentContext?.findRenderObject();
  if (ancestor == null ||
      !ancestor.attached ||
      box is! RenderBox ||
      !box.attached ||
      !box.hasSize) {
    return null;
  }

  final topLeft = ancestor.globalToLocal(box.localToGlobal(Offset.zero));
  final bottomRight = ancestor.globalToLocal(
    box.localToGlobal(box.size.bottomRight(Offset.zero)),
  );
  return Rect.fromPoints(topLeft, bottomRight);
}

class _TutorialOverlay extends StatefulWidget {
  const _TutorialOverlay({
    required this.tutorial,
    required this.controller,
    required this.overlayState,
  });

  final Tutorial tutorial;
  final TutorialController controller;
  final OverlayState overlayState;

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay> {
  final GlobalKey _bubbleKey = GlobalKey();

  /// Height of the bubble as last laid out. Needed to place a bubble that
  /// sits above its target; corrected after the first frame of each step.
  double _bubbleHeight = 134;

  /// Where the current step's target was last seen, used while it is
  /// momentarily not laid out (e.g. scrolled out of a lazy list).
  Rect? _lastTarget;
  int? _lastTargetStep;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  void _measureBubble() {
    if (!mounted) return;
    final box = _bubbleKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize && box.size.height != _bubbleHeight) {
      setState(() => _bubbleHeight = box.size.height);
    }
  }

  Rect? _targetRect(int step, RenderBox? overlayBox) {
    final rect = _rectOf(widget.tutorial.items[step].targetKey, overlayBox);
    if (rect != null) {
      _lastTarget = rect;
      _lastTargetStep = step;
      return rect;
    }
    return _lastTargetStep == step ? _lastTarget : null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: widget.controller.index,
      builder: (context, step, _) {
        if (step == null) return const SizedBox.shrink();

        // Laid out after the page below it, so the target's position is the
        // one from this very frame (e.g. right after a rotation).
        return LayoutBuilder(
          builder: (context, constraints) {
            final overlayBox =
                widget.overlayState.context.findRenderObject() as RenderBox?;
            final target = _targetRect(step, overlayBox);
            if (target == null) return const SizedBox.shrink();

            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _measureBubble(),
            );

            final item = widget.tutorial.items[step];
            final layout = TutorialLayout.compute(
              overlaySize: constraints.biggest,
              target: target,
              bubbleHeight: _bubbleHeight,
            );

            return _TutorialStepView(
              style: widget.tutorial.style,
              controller: widget.controller,
              item: item,
              step: step,
              target: target,
              anchor: item.animationAnchorKey == null
                  ? target
                  : _rectOf(item.animationAnchorKey!, overlayBox) ?? target,
              layout: layout,
              bubbleKey: _bubbleKey,
            );
          },
        );
      },
    );
  }
}

class _TutorialStepView extends StatelessWidget {
  const _TutorialStepView({
    required this.style,
    required this.controller,
    required this.item,
    required this.step,
    required this.target,
    required this.anchor,
    required this.layout,
    required this.bubbleKey,
  });

  final TutorialStyle style;
  final TutorialController controller;
  final TutorialItem item;
  final int step;
  final Rect target;
  final Rect anchor;
  final TutorialLayout layout;
  final GlobalKey bubbleKey;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = style.bubbleColor;

    return Stack(
      children: [
        // Covers the whole overlay, the cut-out included, so the app below
        // receives no taps while the tutorial is on screen.
        Positioned.fill(
          child: TweenAnimationBuilder<Rect?>(
            tween: RectTween(end: target.inflate(style.highlightPadding)),
            duration: style.animationDuration,
            curve: style.animationCurve,
            builder: (context, hole, _) => CustomPaint(
              painter: TutorialBackgroundPainter(
                hole: hole!,
                holeRadius: style.highlightRadius,
                color: style.overlayColor,
              ),
            ),
          ),
        ),
        // Always in the children list, even for steps without an animation:
        // dropping the slot would shift the bubble's subtree up a position and
        // rebuild it from scratch on every such step change.
        _StepAnimation(
          style: style,
          animation: item.animation,
          target: target,
          anchor: anchor,
        ),
        _Pointer(style: style, layout: layout, color: bubbleColor),
        _Bubble(
          key: bubbleKey,
          style: style,
          controller: controller,
          item: item,
          step: step,
          layout: layout,
          color: bubbleColor,
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.style,
    required this.controller,
    required this.item,
    required this.step,
    required this.layout,
    required this.color,
    super.key,
  });

  final TutorialStyle style;
  final TutorialController controller;
  final TutorialItem item;
  final int step;
  final TutorialLayout layout;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isFirst = step == 0;
    final isLast = step == controller.stepCount - 1;
    final foreground = style.foregroundColor;

    // The overlay has no Material (or other design-system) ancestor providing
    // a text style, so set a complete one rather than inherit WidgetsApp's
    // debug style.
    final baseTextStyle = TextStyle(
      color: foreground,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none,
    );

    return AnimatedPositioned(
      top: layout.bubbleTop,
      left: layout.bubbleLeft,
      right: layout.bubbleRight,
      duration: style.animationDuration,
      curve: style.animationCurve,
      child: DefaultTextStyle(
        style: baseTextStyle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: style.bubbleBorderRadius,
            color: color,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TutorialButton(
                  label: style.closeLabel,
                  icon:
                      style.closeIcon ??
                      TutorialIcon(TutorialIconShape.close, color: foreground),
                  onPressed: () => controller.finish(TutorialResult.closed),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    item.description,
                    style: style.descriptionTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kept in the row on the first step so the counter stays
                    // centred, but neither visible nor reachable.
                    ExcludeSemantics(
                      excluding: isFirst,
                      child: AnimatedOpacity(
                        duration: style.animationDuration,
                        opacity: isFirst ? 0 : 1,
                        child: TutorialButton(
                          label: style.previousLabel,
                          enabled: !isFirst,
                          icon:
                              style.previousIcon ??
                              TutorialIcon(
                                TutorialIconShape.previous,
                                color: foreground,
                              ),
                          onPressed: controller.previous,
                        ),
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        style: style.pageCounterTextStyle,
                        children: [
                          TextSpan(
                            text: '${step + 1}',
                            style: style.currentPageTextStyle,
                          ),
                          TextSpan(text: ' / ${controller.stepCount}'),
                        ],
                      ),
                    ),
                    TutorialButton(
                      label: isLast ? style.doneLabel : style.nextLabel,
                      icon: isLast
                          ? style.doneIcon ??
                                TutorialIcon(
                                  TutorialIconShape.done,
                                  color: foreground,
                                )
                          : style.nextIcon ??
                                TutorialIcon(
                                  TutorialIconShape.next,
                                  color: foreground,
                                ),
                      onPressed: controller.next,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pointer extends StatelessWidget {
  const _Pointer({
    required this.style,
    required this.layout,
    required this.color,
  });

  final TutorialStyle style;
  final TutorialLayout layout;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      top: layout.pointerOffset.dy,
      left: layout.pointerOffset.dx,
      duration: style.animationDuration,
      curve: style.animationCurve,
      child: ClipPath(
        clipper: TutorialPointerClipper(flip: layout.flipped),
        child: SizedBox.fromSize(
          size: kTutorialPointerSize,
          child: ColoredBox(color: color),
        ),
      ),
    );
  }
}

/// Illustrative animation for a step: a square as tall as the highlighted
/// target, sitting over it, centred horizontally on the animation anchor.
///
/// Rendered above the dimmed background but below the bubble, and always
/// transparent to pointer events.
class _StepAnimation extends StatelessWidget {
  const _StepAnimation({
    required this.style,
    required this.animation,
    required this.target,
    required this.anchor,
  });

  final TutorialStyle style;
  final Widget? animation;
  final Rect target;
  final Rect anchor;

  @override
  Widget build(BuildContext context) {
    final animation = this.animation;
    if (animation == null) return const SizedBox.shrink();

    // The target gives the vertical extent, the anchor the horizontal centre,
    // so a gesture that moves the whole target can still be shown starting
    // from the small control the target is grabbed by.
    final side = target.height;

    return AnimatedPositioned(
      top: target.top,
      left: anchor.center.dx - side / 2,
      width: side,
      height: side,
      duration: style.animationDuration,
      curve: style.animationCurve,
      child: IgnorePointer(child: animation),
    );
  }
}
