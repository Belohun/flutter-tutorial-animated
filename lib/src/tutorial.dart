import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'tutorial_barrier.dart';
import 'tutorial_bubble.dart';
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
    this.barrier = TutorialBarrier.opaque,
    this.useRootOverlay = false,
    this.targetTimeout = const Duration(seconds: 10),
  });

  /// The steps, in order.
  final List<TutorialItem> items;

  /// Visual configuration.
  final TutorialStyle style;

  /// What the dimmed background does with taps, for steps that don't set
  /// their own [TutorialItem.barrier].
  final TutorialBarrier barrier;

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
  Future<TutorialResult> show(BuildContext context) => start(context).result;

  /// Shows the tutorial over the [Overlay] of [context] and returns a
  /// [TutorialSession] that moves it on or closes it from code.
  ///
  /// Use it when the app decides when a step is done, e.g. once the user
  /// has done what the step describes; pair it with a
  /// [TutorialStyle.bubbleBuilder] that shows no buttons.
  TutorialSession start(BuildContext context) {
    assert(items.isNotEmpty, 'A tutorial needs at least one item');

    final overlayState = Overlay.of(context, rootOverlay: useRootOverlay);
    final controller = TutorialController(
      stepCount: items.length,
      prepareStep: _prepareStep,
    );
    _run(controller, overlayState);
    return TutorialSession._(controller);
  }

  Future<void> _run(
    TutorialController controller,
    OverlayState overlayState,
  ) async {
    await controller.start();
    if (!controller.isFinished && !overlayState.mounted) {
      controller.finish(TutorialResult.targetNotFound);
    }
    if (controller.isFinished) {
      controller.dispose();
      return;
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
  }

  Future<bool> _prepareStep(int step) async {
    final item = items[step];
    await item.beforeStep?.call();
    return _waitForLayout(item);
  }

  /// Polls a fixed number of times rather than against a clock, so the
  /// timeout also holds under the fake clock of widget tests.
  Future<bool> _waitForLayout(TutorialItem item) async {
    final attempts =
        targetTimeout.inMicroseconds ~/ _layoutPollInterval.inMicroseconds;

    for (var attempt = 0; !_isLaidOut(item); attempt++) {
      if (attempt >= attempts) return false;
      await Future<void>.delayed(_layoutPollInterval);
    }
    return true;
  }

  static bool _isLaidOut(TutorialItem item) {
    final targetRect = item.targetRect;
    if (targetRect != null) {
      final rect = targetRect();
      return rect != null && rect.isFinite;
    }
    final renderObject = item.targetKey?.currentContext?.findRenderObject();
    return renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize &&
        renderObject.size.isFinite;
  }
}

/// A running [Tutorial], returned by [Tutorial.start] to move it on or close
/// it from code.
class TutorialSession {
  TutorialSession._(this._controller);

  final TutorialController _controller;

  /// Completes once the tutorial is finished.
  Future<TutorialResult> get result => _controller.result;

  /// Whether the tutorial has finished.
  bool get isFinished => _controller.isFinished;

  /// Index of the step on screen, or `null` before the first one is shown.
  ValueListenable<int?> get step => _controller.index;

  /// Moves to the next step, or completes the tutorial on the last one.
  /// Does nothing before the first step is shown.
  Future<void> next() => _controller.next();

  /// Moves to the previous step. Does nothing on the first one.
  Future<void> previous() => _controller.previous();

  /// Finishes the tutorial with [result], [TutorialResult.closed] by
  /// default. Later calls are ignored.
  void finish([TutorialResult result = TutorialResult.closed]) =>
      _controller.finish(result);
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

/// Bounds of [item]'s target in [ancestor]'s coordinates, or `null` when it
/// is not on screen right now.
Rect? _targetOf(TutorialItem item, RenderBox? ancestor) {
  final targetRect = item.targetRect;
  if (targetRect == null) return _rectOf(item.targetKey!, ancestor);

  final rect = targetRect();
  if (ancestor == null || !ancestor.attached || rect == null) return null;
  if (!rect.isFinite) return null;
  return Rect.fromPoints(
    ancestor.globalToLocal(rect.topLeft),
    ancestor.globalToLocal(rect.bottomRight),
  );
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

class _TutorialOverlayState extends State<_TutorialOverlay>
    with SingleTickerProviderStateMixin {
  final GlobalKey _bubbleKey = GlobalKey();

  /// Height of the bubble as last laid out. Needed to place a bubble that
  /// sits above its target; corrected after the first frame of each step.
  double _bubbleHeight = 134;

  /// Where the current step's target was last seen, used while it is
  /// momentarily not laid out (e.g. scrolled out of a lazy list).
  Rect? _lastTarget;
  int? _lastTargetStep;

  /// Follows targets given by [TutorialItem.targetRect], which may move on
  /// any frame.
  late final Ticker _follower = createTicker(_follow);
  Duration _now = Duration.zero;

  /// The step being shown, and when its transition from the previous one
  /// ends; until then changes animate, after it they are followed at once.
  int? _shownStep;
  Duration _settlesAt = Duration.zero;

  @override
  void dispose() {
    _follower.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  RenderBox? get _overlayBox =>
      widget.overlayState.context.findRenderObject() as RenderBox?;

  void _measureBubble() {
    if (!mounted) return;
    final box = _bubbleKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize && box.size.height != _bubbleHeight) {
      setState(() => _bubbleHeight = box.size.height);
    }
  }

  void _follow(Duration elapsed) {
    _now = elapsed;
    final step = widget.controller.index.value;
    if (step == null || !mounted) return;
    final rect = _targetOf(widget.tutorial.items[step], _overlayBox);
    if (rect != null && rect != _lastTarget) setState(() {});
  }

  /// Runs the follower only while the step on screen has a target that may
  /// move.
  void _syncFollower(int step) {
    final follow = widget.tutorial.items[step].targetRect != null;
    if (follow && !_follower.isActive) {
      // The follower's clock restarts with it.
      _now = Duration.zero;
      _follower.start();
    } else if (!follow && _follower.isActive) {
      _follower.stop();
    }
  }

  Rect? _targetRect(int step, RenderBox? overlayBox) {
    final rect = _targetOf(widget.tutorial.items[step], overlayBox);
    if (rect != null) {
      _lastTarget = rect;
      _lastTargetStep = step;
      return rect;
    }
    return _lastTargetStep == step ? _lastTarget : null;
  }

  /// How long changes of this frame animate: the style's duration while
  /// moving between steps, nothing once settled on one.
  Duration _transitionFor(int step) {
    final duration = widget.tutorial.style.animationDuration;
    if (step != _shownStep) {
      _shownStep = step;
      _settlesAt = _now + duration;
      return duration;
    }
    if (!_follower.isActive) return duration;
    return _now >= _settlesAt ? Duration.zero : duration;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: widget.controller.index,
      builder: (context, step, _) {
        if (step == null) return const SizedBox.shrink();
        _syncFollower(step);

        // Laid out after the page below it, so the target's position is the
        // one from this very frame (e.g. right after a rotation).
        return LayoutBuilder(
          builder: (context, constraints) {
            final overlayBox = _overlayBox;
            final target = _targetRect(step, overlayBox);
            if (target == null) return const SizedBox.shrink();

            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _measureBubble(),
            );

            final item = widget.tutorial.items[step];
            final style = widget.tutorial.style;
            final layout = TutorialLayout.compute(
              overlaySize: constraints.biggest,
              target: target,
              bubbleHeight: _bubbleHeight,
              pointerSize: style.pointerSize,
              pointerOverlap: style.pointerOverlap,
              bubbleMaxWidth: style.bubbleMaxWidth,
            );

            return _TutorialStepView(
              style: style,
              barrier: item.barrier ?? widget.tutorial.barrier,
              transition: _transitionFor(step),
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
    required this.barrier,
    required this.transition,
    required this.controller,
    required this.item,
    required this.step,
    required this.target,
    required this.anchor,
    required this.layout,
    required this.bubbleKey,
  });

  final TutorialStyle style;
  final TutorialBarrier barrier;
  final Duration transition;
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
        // With an opaque barrier it covers the whole overlay, the cut-out
        // included, so the app below receives no taps while the tutorial is
        // on screen.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: barrier == TutorialBarrier.transparent,
            child: TweenAnimationBuilder<Rect?>(
              tween: RectTween(end: target.inflate(style.highlightPadding)),
              duration: transition,
              curve: style.animationCurve,
              builder: (context, hole, _) => CustomPaint(
                painter: TutorialBackgroundPainter(
                  hole: hole!,
                  holeRadius: style.highlightRadius,
                  color: style.overlayColor,
                  passThroughHole:
                      barrier == TutorialBarrier.passThroughHighlight,
                ),
              ),
            ),
          ),
        ),
        // Always in the children list, even for steps without an animation:
        // dropping the slot would shift the bubble's subtree up a position and
        // rebuild it from scratch on every such step change.
        _StepAnimation(
          duration: transition,
          curve: style.animationCurve,
          animation: item.animation,
          target: target,
          anchor: anchor,
        ),
        _Pointer(
          style: style,
          duration: transition,
          layout: layout,
          color: bubbleColor,
        ),
        _Bubble(
          key: bubbleKey,
          style: style,
          duration: transition,
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
    required this.duration,
    required this.controller,
    required this.item,
    required this.step,
    required this.layout,
    required this.color,
    super.key,
  });

  final TutorialStyle style;
  final Duration duration;
  final TutorialController controller;
  final TutorialItem item;
  final int step;
  final TutorialLayout layout;
  final Color color;

  @override
  Widget build(BuildContext context) {
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

    final bubbleBuilder = style.bubbleBuilder;
    return AnimatedPositioned(
      top: layout.bubbleTop,
      left: layout.bubbleLeft,
      right: layout.bubbleRight,
      duration: duration,
      curve: style.animationCurve,
      child: DefaultTextStyle(
        style: baseTextStyle,
        child: bubbleBuilder == null
            ? _defaultBubble(foreground)
            : Builder(
                builder: (context) => bubbleBuilder(
                  context,
                  TutorialBubble(
                    item: item,
                    step: step,
                    stepCount: controller.stepCount,
                    pointerDirection: layout.flipped
                        ? AxisDirection.down
                        : AxisDirection.up,
                    pointerX: layout.pointerX,
                    next: controller.next,
                    previous: controller.previous,
                    close: () => controller.finish(TutorialResult.closed),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _defaultBubble(Color foreground) {
    final isFirst = step == 0;
    final isLast = step == controller.stepCount - 1;

    return DecoratedBox(
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
    );
  }
}

class _Pointer extends StatelessWidget {
  const _Pointer({
    required this.style,
    required this.duration,
    required this.layout,
    required this.color,
  });

  final TutorialStyle style;
  final Duration duration;
  final TutorialLayout layout;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pointerBuilder = style.pointerBuilder;
    return AnimatedPositioned(
      top: layout.pointerOffset.dy,
      left: layout.pointerOffset.dx,
      duration: duration,
      curve: style.animationCurve,
      child: SizedBox.fromSize(
        size: style.pointerSize,
        child: pointerBuilder == null
            ? ClipPath(
                clipper: TutorialPointerClipper(flip: layout.flipped),
                child: ColoredBox(color: color),
              )
            : pointerBuilder(
                context,
                layout.flipped ? AxisDirection.down : AxisDirection.up,
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
    required this.duration,
    required this.curve,
    required this.animation,
    required this.target,
    required this.anchor,
  });

  final Duration duration;
  final Curve curve;
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
      duration: duration,
      curve: curve,
      child: IgnorePointer(child: animation),
    );
  }
}
