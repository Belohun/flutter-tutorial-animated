import 'package:flutter/widgets.dart';

/// Shapes of the built-in icons, drawn with strokes so the package needs no
/// icon font.
enum TutorialIconShape {
  /// A cross.
  close,

  /// A chevron pointing back (left in LTR).
  previous,

  /// A chevron pointing forward (right in LTR).
  next,

  /// A check mark.
  done,
}

/// A built-in stroke icon.
class TutorialIcon extends StatelessWidget {
  /// Creates a built-in icon.
  const TutorialIcon(this.shape, {required this.color, super.key});

  /// What to draw.
  final TutorialIconShape shape;

  /// Stroke colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(20),
      painter: _TutorialIconPainter(
        shape: shape,
        color: color,
        textDirection: Directionality.of(context),
      ),
    );
  }
}

class _TutorialIconPainter extends CustomPainter {
  const _TutorialIconPainter({
    required this.shape,
    required this.color,
    required this.textDirection,
  });

  final TutorialIconShape shape;
  final Color color;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide / 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Points on a 0..1 grid, mirrored for chevrons in RTL.
    final rtl = textDirection == TextDirection.rtl;
    Offset at(double x, double y) => Offset(x * size.width, y * size.height);
    Offset chevron(double x, double y) => at(rtl ? 1 - x : x, y);

    final path = switch (shape) {
      TutorialIconShape.close =>
        Path()
          ..moveTo(at(0.25, 0.25).dx, at(0.25, 0.25).dy)
          ..lineTo(at(0.75, 0.75).dx, at(0.75, 0.75).dy)
          ..moveTo(at(0.75, 0.25).dx, at(0.75, 0.25).dy)
          ..lineTo(at(0.25, 0.75).dx, at(0.25, 0.75).dy),
      TutorialIconShape.previous => _polyline([
        chevron(0.62, 0.2),
        chevron(0.32, 0.5),
        chevron(0.62, 0.8),
      ]),
      TutorialIconShape.next => _polyline([
        chevron(0.38, 0.2),
        chevron(0.68, 0.5),
        chevron(0.38, 0.8),
      ]),
      TutorialIconShape.done => _polyline([
        at(0.2, 0.52),
        at(0.42, 0.74),
        at(0.8, 0.3),
      ]),
    };

    canvas.drawPath(path, paint);
  }

  static Path _polyline(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_TutorialIconPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.color != color ||
      oldDelegate.textDirection != textDirection;
}

/// A 48×48 tappable icon that dims while pressed.
class TutorialButton extends StatefulWidget {
  /// Creates a button.
  const TutorialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  /// What the button shows.
  final Widget icon;

  /// Accessibility label.
  final String label;

  /// Called on tap.
  final VoidCallback onPressed;

  /// Whether the button reacts to taps and is announced as enabled.
  final bool enabled;

  @override
  State<TutorialButton> createState() => _TutorialButtonState();
}

class _TutorialButtonState extends State<TutorialButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.enabled ? widget.onPressed : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onPressed : null,
        onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
        onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
        onTapCancel: widget.enabled ? () => _setPressed(false) : null,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _pressed ? 0.5 : 1,
              child: widget.icon,
            ),
          ),
        ),
      ),
    );
  }
}
