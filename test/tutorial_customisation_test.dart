import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tutorial_animated/flutter_tutorial_animated.dart';

final _targetKey = GlobalKey(debugLabel: 'target');

/// A page with a tappable box at the top and one below it, counting taps.
class _Page extends StatelessWidget {
  const _Page({required this.taps});

  final ValueNotifier<int> taps;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps.value++,
            child: SizedBox(key: _targetKey, width: 100, height: 50),
          ),
          Expanded(
            child: GestureDetector(
              key: const Key('elsewhere'),
              behavior: HitTestBehavior.opaque,
              onTap: () => taps.value += 10,
            ),
          ),
        ],
      ),
    );
  }
}

Future<BuildContext> _pumpPage(
  WidgetTester tester, {
  ValueNotifier<int>? taps,
}) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: _Page(taps: taps ?? ValueNotifier(0)),
    ),
  );
  return tester.element(find.byType(_Page));
}

TutorialItem _item({TutorialBarrier? barrier, String text = 'Step'}) =>
    TutorialItem(targetKey: _targetKey, description: text, barrier: barrier);

void main() {
  group('barrier', () {
    Future<int> tapsWith(
      WidgetTester tester,
      TutorialBarrier barrier,
      Finder where,
    ) async {
      final taps = ValueNotifier(0);
      final context = await _pumpPage(tester, taps: taps);
      Tutorial(barrier: barrier, items: [_item()]).show(context).ignore();
      await tester.pumpAndSettle();
      await tester.tap(where, warnIfMissed: false);
      return taps.value;
    }

    final target = find.byKey(_targetKey);
    final elsewhere = find.byKey(const Key('elsewhere'));

    testWidgets('opaque takes every tap', (tester) async {
      expect(await tapsWith(tester, TutorialBarrier.opaque, target), 0);
    });

    testWidgets('passThroughHighlight lets the highlight be tapped', (
      tester,
    ) async {
      expect(
        await tapsWith(tester, TutorialBarrier.passThroughHighlight, target),
        1,
      );
    });

    testWidgets('passThroughHighlight takes taps around it', (tester) async {
      expect(
        await tapsWith(tester, TutorialBarrier.passThroughHighlight, elsewhere),
        0,
      );
    });

    testWidgets('transparent lets everything but the bubble through', (
      tester,
    ) async {
      final taps = ValueNotifier(0);
      final context = await _pumpPage(tester, taps: taps);
      Tutorial(
        barrier: TutorialBarrier.transparent,
        items: [_item()],
      ).show(context).ignore();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_targetKey));
      await tester.tapAt(const Offset(10, 500));
      expect(taps.value, 11);
    });

    testWidgets('a step can set its own barrier', (tester) async {
      final taps = ValueNotifier(0);
      final context = await _pumpPage(tester, taps: taps);
      Tutorial(
        items: [_item(barrier: TutorialBarrier.passThroughHighlight)],
      ).show(context).ignore();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_targetKey));
      expect(taps.value, 1);
    });
  });

  testWidgets('a bubble builder replaces the bubble', (tester) async {
    final context = await _pumpPage(tester);
    final bubbles = <TutorialBubble>[];
    final pointers = <AxisDirection>[];

    final result = Tutorial(
      style: TutorialStyle(
        bubbleMaxWidth: 200,
        pointerSize: const Size(10, 10),
        pointerBuilder: (context, direction) {
          pointers.add(direction);
          return const SizedBox(key: Key('pointer'));
        },
        bubbleBuilder: (context, bubble) {
          bubbles.add(bubble);
          return GestureDetector(
            onTap: bubble.next,
            child: SizedBox(
              key: const Key('bubble'),
              height: 40,
              child: Text('Custom ${bubble.description}'),
            ),
          );
        },
      ),
      items: [
        _item(text: 'one'),
        _item(text: 'two'),
      ],
    ).show(context);
    await tester.pumpAndSettle();

    expect(find.text('Custom one'), findsOneWidget);
    expect(find.bySemanticsLabel('Next'), findsNothing);
    expect(tester.getSize(find.byKey(const Key('bubble'))).width, 200);
    expect(
      tester.getSize(find.byKey(const Key('pointer'))),
      const Size(10, 10),
    );
    expect(pointers.last, AxisDirection.up);
    expect(bubbles.last.isFirst, isTrue);
    expect(bubbles.last.stepCount, 2);
    // The 200 px bubble is centred on the pointer.
    expect(bubbles.last.pointerX, 100);

    await tester.tap(find.byKey(const Key('bubble')));
    await tester.pumpAndSettle();
    expect(find.text('Custom two'), findsOneWidget);
    expect(bubbles.last.isLast, isTrue);

    await tester.tap(find.byKey(const Key('bubble')));
    await tester.pumpAndSettle();
    expect(await result, TutorialResult.completed);
  });

  group('start', () {
    testWidgets('moves on and finishes from code', (tester) async {
      final context = await _pumpPage(tester);

      final session = Tutorial(
        items: [
          _item(text: 'one'),
          _item(text: 'two'),
        ],
      ).start(context);
      await tester.pumpAndSettle();
      expect(session.step.value, 0);

      await session.next();
      await tester.pumpAndSettle();
      expect(find.text('two'), findsOneWidget);

      session.finish(TutorialResult.completed);
      await tester.pumpAndSettle();
      expect(find.text('two'), findsNothing);
      expect(session.isFinished, isTrue);
      expect(await session.result, TutorialResult.completed);
    });

    testWidgets('finishing before the first step shows nothing', (
      tester,
    ) async {
      final context = await _pumpPage(tester);

      final session = Tutorial(items: [_item()]).start(context)..finish();
      await tester.pumpAndSettle();

      expect(find.text('Step'), findsNothing);
      expect(await session.result, TutorialResult.closed);
    });
  });

  group('targetRect', () {
    testWidgets('highlights an area that is not a widget, and follows it', (
      tester,
    ) async {
      final context = await _pumpPage(tester);
      var area = const Rect.fromLTWH(200, 100, 40, 40);

      final session = Tutorial(
        style: const TutorialStyle(
          pointerBuilder: _pointer,
          pointerSize: Size(10, 10),
        ),
        items: [TutorialItem(targetRect: () => area, description: 'Area')],
      ).start(context);
      // Lets the step settle without pumpAndSettle, which never returns
      // while a moving target is followed.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final pointer = find.byKey(const Key('pointer'));
      expect(find.text('Area'), findsOneWidget);
      expect(tester.getTopLeft(pointer), const Offset(215, 152));

      area = area.shift(const Offset(100, 0));
      await tester.pump();
      await tester.pump();
      expect(tester.getTopLeft(pointer), const Offset(315, 152));

      session.finish();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Area'), findsNothing);
    });

    testWidgets('waits for the area to be on screen', (tester) async {
      final context = await _pumpPage(tester);
      Rect? area;

      final result = Tutorial(
        targetTimeout: const Duration(seconds: 1),
        items: [TutorialItem(targetRect: () => area, description: 'Area')],
      ).show(context);
      await tester.pump(const Duration(seconds: 2));

      expect(await result, TutorialResult.targetNotFound);
    });

    test('needs exactly one of targetKey and targetRect', () {
      expect(() => TutorialItem(description: 'Nothing'), throwsAssertionError);
      expect(
        () => TutorialItem(
          description: 'Both',
          targetKey: _targetKey,
          targetRect: () => Rect.zero,
        ),
        throwsAssertionError,
      );
    });
  });
}

Widget _pointer(BuildContext context, AxisDirection direction) =>
    const SizedBox(key: Key('pointer'));
