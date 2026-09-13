import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jem_notes/main.dart';

void main() {
  testWidgets('app shell renders its title and strapline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const JemNotesApp());

    // AppBar title. Scoped to the AppBar so it cannot accidentally match a
    // body Text with the same string later on.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(JemNotesApp.title),
      ),
      findsOneWidget,
    );
    expect(find.text('Learn to read music'), findsOneWidget);
  });
  testWidgets('both renderer harnesses are reachable from the home screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JemNotesApp());
    await tester.tap(find.text('Staff renderer'));
    await tester.pumpAndSettle();
    expect(find.text('C4 · treble'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keyboard'));
    await tester.pumpAndSettle();
    expect(find.text('Press a key'), findsOneWidget);
  });
}
