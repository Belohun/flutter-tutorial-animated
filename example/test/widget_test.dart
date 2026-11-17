import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_tutorial_animated_example/main.dart';

void main() {
  testWidgets('shows the tutorial on start and walks through it', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Search through all of your notes from here.'),
      findsOneWidget,
    );

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.bySemanticsLabel('Next'));
      // The step animation repeats forever, so pumpAndSettle would time out.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('Tap here to write a new note.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Notes (tutorial: completed)'), findsOneWidget);
  });
}
