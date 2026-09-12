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
}
