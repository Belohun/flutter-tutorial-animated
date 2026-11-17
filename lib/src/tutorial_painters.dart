import 'package:flutter/widgets.dart';

/// Paints [color] over the whole canvas except for a rounded [hole].
class TutorialBackgroundPainter extends CustomPainter {
  /// Creates a background painter.
  const TutorialBackgroundPainter({
    required this.hole,
    required this.holeRadius,
    required this.color,
    this.passThroughHole = false,
  });

  /// Area left uncovered, in the painter's coordinates.
  final Rect hole;

  /// Corner radius of [hole].
  final Radius holeRadius;

  /// Colour of the covered area.
  final Color color;

  /// Whether taps inside [hole] go through to whatever is below.
  final bool passThroughHole;

  RRect get _holeRRect => RRect.fromRectAndRadius(hole, holeRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(_holeRRect),
    );

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool hitTest(Offset position) =>
      !(passThroughHole && _holeRRect.contains(position));

  @override
  bool shouldRepaint(TutorialBackgroundPainter oldDelegate) =>
      oldDelegate.passThroughHole != passThroughHole ||
      oldDelegate.hole != hole ||
      oldDelegate.holeRadius != holeRadius ||
      oldDelegate.color != color;
}

/// Clips a triangle with a rounded tip pointing up, or down when [flip] is
/// set.
class TutorialPointerClipper extends CustomClipper<Path> {
  /// Creates a pointer clipper.
  const TutorialPointerClipper({this.flip = false});

  /// Whether the tip points down instead of up.
  final bool flip;

  static const double _tipRadius = 3;

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;

    // Flipping is a half-turn around the centre: (x, y) -> (w - x, h - y).
    Offset point(double x, double y) =>
        flip ? Offset(width - x, height - y) : Offset(x, y);

    final baseStart = point(0, height);
    final baseEnd = point(width, height);
    final tipStart = point(width / 2 + _tipRadius, _tipRadius);
    final tip = point(width / 2, 0);
    final tipEnd = point(width / 2 - _tipRadius, _tipRadius);

    return Path()
      ..moveTo(baseStart.dx, baseStart.dy)
      ..lineTo(baseEnd.dx, baseEnd.dy)
      ..lineTo(tipStart.dx, tipStart.dy)
      ..quadraticBezierTo(tip.dx, tip.dy, tipEnd.dx, tipEnd.dy)
      ..close();
  }

  @override
  bool shouldReclip(TutorialPointerClipper oldClipper) =>
      oldClipper.flip != flip;
}
