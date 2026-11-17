import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tutorial_animated/flutter_tutorial_animated.dart';
import 'package:flutter_tutorial_animated/src/tutorial_button.dart';

final _firstKey = GlobalKey(debugLabel: 'first');
final _secondKey = GlobalKey(debugLabel: 'second');
final _hiddenKey = GlobalKey(debugLabel: 'hidden');
final _showHidden = ValueNotifier(false);

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: Column(
        children: [
          SizedBox(key: _firstKey, width: 100, height: 50),
          ValueListenableBuilder(
            valueListenable: _showHidden,
            builder: (context, show, _) => show
                ? SizedBox(key: _hiddenKey, width: 10, height: 10)
                : const SizedBox.shrink(),
          ),
          const Spacer(),
          SizedBox(key: _secondKey, width: 100, height: 50),
        ],
      ),
    );
  }
}

Future<BuildContext> _pumpPage(WidgetTester tester) async {
  // A bare WidgetsApp: the package must not need Material.
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: const _Page(),
    ),
  );
  return tester.element(find.byType(_Page));
}

Tutorial _twoSteps({Future<void> Function()? beforeSecondStep}) => Tutorial(
  items: [
    TutorialItem(targetKey: _firstKey, description: 'First step'),
    TutorialItem(
      targetKey: _secondKey,
      description: 'Second step',
      beforeStep: beforeSecondStep,
    ),
  ],
);

Finder _button(String label) => find.bySemanticsLabel(label);

void main() {
  setUp(() => _showHidden.value = false);

  testWidgets('shows the first step, then the second', (tester) async {
    final context = await _pumpPage(tester);

    _twoSteps().show(context).ignore();
    await tester.pumpAndSettle();

    expect(find.text('First step'), findsOneWidget);
    expect(find.text('Second step'), findsNothing);

    await tester.tap(_button('Next'));
    await tester.pumpAndSettle();

    expect(find.text('First step'), findsNothing);
    expect(find.text('Second step'), findsOneWidget);
  });

  testWidgets('completes with completed after the last step', (tester) async {
    final context = await _pumpPage(tester);

    final result = _twoSteps().show(context);
    await tester.pumpAndSettle();
    await tester.tap(_button('Next'));
    await tester.pumpAndSettle();
    await tester.tap(_button('Done'));
    await tester.pumpAndSettle();

    expect(await result, TutorialResult.completed);
    expect(find.text('Second step'), findsNothing);
  });

  testWidgets('completes with closed when closed early', (tester) async {
    final context = await _pumpPage(tester);

    final result = _twoSteps().show(context);
    await tester.pumpAndSettle();
    await tester.tap(_button('Close'));
    await tester.pumpAndSettle();

    expect(await result, TutorialResult.closed);
    expect(find.text('First step'), findsNothing);
  });

  testWidgets('previous button is hidden and inert on the first step', (
    tester,
  ) async {
    final context = await _pumpPage(tester);

    _twoSteps().show(context).ignore();
    await tester.pumpAndSettle();

    expect(_button('Previous'), findsNothing);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is TutorialButton && widget.label == 'Previous',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First step'), findsOneWidget);
  });

  testWidgets('goes back to the previous step', (tester) async {
    final context = await _pumpPage(tester);

    _twoSteps().show(context).ignore();
    await tester.pumpAndSettle();
    await tester.tap(_button('Next'));
    await tester.pumpAndSettle();
    await tester.tap(_button('Previous'));
    await tester.pumpAndSettle();

    expect(find.text('First step'), findsOneWidget);
  });

  testWidgets('awaits beforeStep and ignores taps meanwhile', (tester) async {
    final context = await _pumpPage(tester);
    var beforeStepCalls = 0;

    _twoSteps(
      beforeSecondStep: () async {
        beforeStepCalls++;
        await Future<void>.delayed(const Duration(seconds: 1));
      },
    ).show(context).ignore();
    await tester.pumpAndSettle();

    await tester.tap(_button('Next'));
    await tester.pump();
    await tester.tap(_button('Next'));
    await tester.pump();

    expect(find.text('First step'), findsOneWidget);
    expect(beforeStepCalls, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Second step'), findsOneWidget);
  });

  testWidgets('completes with targetNotFound when a target never shows up', (
    tester,
  ) async {
    final context = await _pumpPage(tester);

    final result = Tutorial(
      targetTimeout: const Duration(seconds: 1),
      items: [TutorialItem(targetKey: _hiddenKey, description: 'Hidden')],
    ).show(context);
    await tester.pump(const Duration(seconds: 2));

    expect(await result, TutorialResult.targetNotFound);
    expect(find.text('Hidden'), findsNothing);
  });

  testWidgets('waits for a target that is laid out later', (tester) async {
    final context = await _pumpPage(tester);

    final result = Tutorial(
      items: [TutorialItem(targetKey: _hiddenKey, description: 'Late')],
    ).show(context);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Late'), findsNothing);

    _showHidden.value = true;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Late'), findsOneWidget);

    await tester.tap(_button('Close'));
    await tester.pumpAndSettle();
    expect(await result, TutorialResult.closed);
  });

  testWidgets('step animation is shown and ignores pointers', (tester) async {
    final context = await _pumpPage(tester);
    const animationKey = Key('animation');

    Tutorial(
      items: [
        TutorialItem(
          targetKey: _secondKey,
          description: 'Animated',
          animation: const ColoredBox(
            key: animationKey,
            color: Color(0xFFFF0000),
          ),
        ),
      ],
    ).show(context).ignore();
    await tester.pumpAndSettle();

    final animation = find.byKey(animationKey);
    expect(animation, findsOneWidget);
    // A square as tall as the 50 px target.
    expect(tester.getSize(animation), const Size(50, 50));
    expect(
      find.ancestor(of: animation, matching: find.byType(IgnorePointer)),
      findsWidgets,
    );
  });
}
