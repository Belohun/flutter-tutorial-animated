import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tutorial_animated/src/tutorial_layout.dart';

void main() {
  const overlaySize = Size(400, 800);
  const bubbleHeight = 100.0;

  TutorialLayout layoutFor(Rect target) => TutorialLayout.compute(
    overlaySize: overlaySize,
    target: target,
    bubbleHeight: bubbleHeight,
  );

  test('target in the top half gets the bubble below it', () {
    final layout = layoutFor(const Rect.fromLTWH(180, 100, 40, 40));

    expect(layout.flipped, isFalse);
    expect(layout.pointerOffset.dy, 140 + kTutorialVerticalPadding);
    expect(
      layout.bubbleTop,
      layout.pointerOffset.dy + kTutorialPointerSize.height - 1,
    );
  });

  test('target in the bottom half gets the bubble above it', () {
    final layout = layoutFor(const Rect.fromLTWH(180, 600, 40, 40));

    expect(layout.flipped, isTrue);
    expect(
      layout.pointerOffset.dy,
      600 - kTutorialVerticalPadding - kTutorialPointerSize.height,
    );
    expect(layout.bubbleTop, layout.pointerOffset.dy - bubbleHeight + 1);
  });

  test('pointer is centred on the target', () {
    final layout = layoutFor(const Rect.fromLTWH(180, 100, 40, 40));

    expect(layout.pointerOffset.dx + kTutorialPointerSize.width / 2, 200);
  });

  test('bubble keeps the default insets away from the edges', () {
    final layout = layoutFor(const Rect.fromLTWH(180, 100, 40, 40));

    expect(layout.bubbleLeft, kTutorialHorizontalPadding);
    expect(layout.bubbleRight, kTutorialHorizontalPadding);
  });

  test('bubble shifts left, keeping its width, for a target at the left '
      'edge', () {
    final layout = layoutFor(const Rect.fromLTWH(0, 100, 40, 40));

    expect(
      layout.pointerOffset.dx - layout.bubbleLeft,
      kTutorialPointerToCornerMinDistance,
    );
    expect(
      layout.bubbleLeft + layout.bubbleRight,
      kTutorialHorizontalPadding * 2,
    );
  });

  test('bubble shifts right, keeping its width, for a target at the right '
      'edge', () {
    final layout = layoutFor(const Rect.fromLTWH(360, 100, 40, 40));

    final pointerRight =
        overlaySize.width -
        layout.pointerOffset.dx -
        kTutorialPointerSize.width;
    expect(
      pointerRight - layout.bubbleRight,
      kTutorialPointerToCornerMinDistance,
    );
    expect(
      layout.bubbleLeft + layout.bubbleRight,
      kTutorialHorizontalPadding * 2,
    );
  });

  group('bubbleMaxWidth', () {
    TutorialLayout narrow(double targetX) => TutorialLayout.compute(
      overlaySize: overlaySize,
      target: Rect.fromLTWH(targetX - 20, 100, 40, 40),
      bubbleHeight: bubbleHeight,
      bubbleMaxWidth: 200,
    );

    test('centres a narrower bubble on the pointer', () {
      final layout = narrow(200);

      expect(layout.bubbleLeft, 100);
      expect(layout.bubbleRight, 100);
      expect(layout.pointerX, 100);
    });

    test('keeps a narrower bubble inside the margins', () {
      final layout = narrow(90);

      expect(layout.bubbleLeft, kTutorialHorizontalPadding);
      expect(layout.pointerX, 90 - kTutorialHorizontalPadding);
    });

    test('never wider than the overlay allows', () {
      final layout = TutorialLayout.compute(
        overlaySize: overlaySize,
        target: const Rect.fromLTWH(180, 100, 40, 40),
        bubbleHeight: bubbleHeight,
        bubbleMaxWidth: 1000,
      );

      expect(layout.bubbleLeft, kTutorialHorizontalPadding);
      expect(layout.bubbleRight, kTutorialHorizontalPadding);
    });
  });

  test('pointer size and overlap place the bubble', () {
    final layout = TutorialLayout.compute(
      overlaySize: overlaySize,
      target: const Rect.fromLTWH(180, 100, 40, 40),
      bubbleHeight: bubbleHeight,
      pointerSize: const Size(20, 10),
      pointerOverlap: 4,
    );

    expect(layout.pointerOffset, Offset(190, 140 + kTutorialVerticalPadding));
    expect(layout.bubbleTop, layout.pointerOffset.dy + 10 - 4);
  });
}
