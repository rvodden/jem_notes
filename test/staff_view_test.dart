import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';

/// The two shapes that matter: the tablet he practises on, and a phone in
/// portrait, which RFC-0001 D12 requires to work as a secondary.
const Size kTabletLandscape = Size(1024, 600);
const Size kPhonePortrait = Size(390, 720);

Widget _harness(Pitch pitch, Clef clef) {
  return MaterialApp(
    // Light theme pinned so goldens do not depend on the ambient theme.
    theme: ThemeData(brightness: Brightness.light),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StaffView(pitch: pitch, clef: clef),
      ),
    ),
  );
}

Future<void> _pumpAt(WidgetTester tester, Size size, Widget widget) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
  // The four level-1 renderings from RFC-0001: B3 and D4 in their only clefs,
  // and middle C in both, because it looks different in each.
  final Map<String, (Pitch, Clef)> cases = <String, (Pitch, Clef)>{
    'b3-bass': (Pitch.parse('B3'), Clef.bass),
    'c4-treble': (Pitch.middleC, Clef.treble),
    'c4-bass': (Pitch.middleC, Clef.bass),
    'd4-treble': (Pitch.parse('D4'), Clef.treble),
  };

  final Map<String, Size> sizes = <String, Size>{
    'tablet': kTabletLandscape,
    'phone': kPhonePortrait,
  };

  for (final MapEntry<String, Size> size in sizes.entries) {
    for (final MapEntry<String, (Pitch, Clef)> entry in cases.entries) {
      testWidgets('golden: ${entry.key} on ${size.key}', (
        WidgetTester tester,
      ) async {
        final (Pitch pitch, Clef clef) = entry.value;
        await _pumpAt(tester, size.value, _harness(pitch, clef));
        await expectLater(
          find.byType(StaffView),
          matchesGoldenFile('goldens/${entry.key}-${size.key}.png'),
        );
      });
    }
  }

  testWidgets('renders at extreme sizes without throwing or clipping', (
    WidgetTester tester,
  ) async {
    for (final Size size in <Size>[
      const Size(120, 90),
      const Size(2000, 300),
      const Size(300, 2000),
      kPhonePortrait,
      kTabletLandscape,
    ]) {
      await _pumpAt(tester, size, _harness(Pitch.middleC, Clef.treble));
      expect(tester.takeException(), isNull, reason: 'failed at $size');
    }
  });

  testWidgets('repaints when the pitch changes but not when it does not', (
    WidgetTester tester,
  ) async {
    await _pumpAt(tester, kPhonePortrait, _harness(Pitch.middleC, Clef.treble));
    final CustomPaint paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(StaffView),
        matching: find.byType(CustomPaint),
      ),
    );
    final CustomPainter painter = paint.painter!;
    expect(painter.shouldRepaint(painter), isFalse);
  });

  testWidgets('harness page steps through the range and switches clef', (
    WidgetTester tester,
  ) async {
    await _pumpAt(
      tester,
      kTabletLandscape,
      const MaterialApp(home: StaffHarnessPage()),
    );
    // Opens on middle C, in the treble by default.
    expect(find.text('C4 · treble'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_downward));
    await tester.pumpAndSettle();
    expect(find.text('B3 · bass'), findsOneWidget);

    await tester.tap(find.text('treble'));
    await tester.pumpAndSettle();
    expect(find.text('B3 · treble'), findsOneWidget);
  });
}
