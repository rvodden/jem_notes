import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';
import 'package:jem_notes/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      JemNotesApp(progress: ProgressController(store: InMemoryProgressStore())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the app opens straight into a round', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    // No home screen, no menu, nothing to read past: the staff and the
    // keyboard are on screen from the first frame (RFC-0001 D13).
    expect(find.byType(StaffView), findsOneWidget);
    expect(find.byType(PianoKeyboard), findsOneWidget);
    expect(find.widgetWithText(AppBar, JemNotesApp.title), findsNothing);
  });

  testWidgets('the debug harnesses are reachable but out of the way', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Staff renderer'));
    await tester.pumpAndSettle();
    expect(find.text('C4 · treble'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keyboard'));
    await tester.pumpAndSettle();
    expect(find.text('Press a key'), findsOneWidget);
  });
}
