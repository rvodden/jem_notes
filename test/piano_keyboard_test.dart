import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';

/// Level 1's note set, per RFC-0001.
final Set<Pitch> kLevel1 = <Pitch>{
  Pitch.parse('B3'),
  Pitch.middleC,
  Pitch.parse('D4'),
};

final Set<Pitch> kAllWhite = Pitch.range(
  Pitch.parse('C3'),
  Pitch.parse('C5'),
).toSet();

/// Keyboard strips, not whole screens: the keyboard occupies a band across the
/// bottom of the exercise.
const Size kTabletStrip = Size(1024, 260);
const Size kPhoneStrip = Size(390, 150);

Widget _harness(
  Size size,
  Set<Pitch> active,
  ValueChanged<PianoKey> onPressed,
) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: PianoKeyboard(activePitches: active, onKeyPressed: onPressed),
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  Set<Pitch> active,
  ValueChanged<PianoKey> onPressed,
) async {
  tester.view.physicalSize = Size(size.width, size.height + 40);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(size, active, onPressed));
  await tester.pumpAndSettle();
}

void main() {
  group('layout', () {
    test('spans C3-C5 with 15 white and 10 black keys', () {
      final PianoKeyboardLayout layout = PianoKeyboardLayout(
        size: kTabletStrip,
      );
      expect(layout.whiteKeys.length, 15);
      expect(layout.blackKeys.length, 10);
    });

    test('has no black key between E-F or B-C', () {
      final PianoKeyboardLayout layout = PianoKeyboardLayout(
        size: kTabletStrip,
      );
      final Set<NoteLetter> lettersWithBlack = layout.blackKeys
          .map((KeyPlacement p) => p.key.naturalBelow.letter)
          .toSet();
      expect(lettersWithBlack.contains(NoteLetter.e), isFalse);
      expect(lettersWithBlack.contains(NoteLetter.b), isFalse);
      expect(lettersWithBlack, <NoteLetter>{
        NoteLetter.c,
        NoteLetter.d,
        NoteLetter.f,
        NoteLetter.g,
        NoteLetter.a,
      });
    });

    test('white keys tile the width without gaps or overlaps', () {
      final PianoKeyboardLayout layout = PianoKeyboardLayout(
        size: kTabletStrip,
      );
      for (int i = 1; i < layout.whiteKeys.length; i++) {
        expect(
          layout.whiteKeys[i].rect.left,
          closeTo(layout.whiteKeys[i - 1].rect.right, 1e-9),
        );
      }
      expect(
        layout.whiteKeys.last.rect.right,
        closeTo(kTabletStrip.width, 1e-9),
      );
    });

    test('black keys are shorter than white ones', () {
      final PianoKeyboardLayout layout = PianoKeyboardLayout(
        size: kTabletStrip,
      );
      for (final KeyPlacement black in layout.blackKeys) {
        expect(black.rect.height, lessThan(kTabletStrip.height));
      }
    });

    test('hit targets stay big enough for a six-year-old', () {
      // The AC thresholds from JEM-2: a fixed 15-key keyboard is exactly what
      // makes these achievable without scrolling.
      expect(
        PianoKeyboardLayout(size: kPhoneStrip).whiteKeyWidth,
        greaterThanOrEqualTo(24),
      );
      expect(
        PianoKeyboardLayout(size: kTabletStrip).whiteKeyWidth,
        greaterThanOrEqualTo(40),
      );
    });
  });

  group('hit testing', () {
    final PianoKeyboardLayout layout = PianoKeyboardLayout(size: kTabletStrip);

    test('a tap where a black key overlaps a white one hits the black key', () {
      final KeyPlacement black = layout.blackKeys.first;
      // Dead centre of the black key, which is also inside the white key drawn
      // behind it — the case that silently breaks if hit order is reversed.
      final KeyPlacement? hit = layout.hitTest(black.rect.center);
      expect(hit?.key.isBlack, isTrue);
      expect(hit?.key, black.key);

      // The same x, but below where the black key ends, is the white key.
      final Offset lower = Offset(
        black.rect.center.dx,
        kTabletStrip.height - 4,
      );
      expect(layout.hitTest(lower)?.key.isBlack, isFalse);
    });

    test('taps land on the expected white keys', () {
      final KeyPlacement first = layout.whiteKeys.first;
      expect(
        layout
            .hitTest(Offset(first.rect.center.dx, kTabletStrip.height - 4))
            ?.key
            .naturalBelow,
        Pitch.parse('C3'),
      );
      final KeyPlacement last = layout.whiteKeys.last;
      expect(
        layout
            .hitTest(Offset(last.rect.center.dx, kTabletStrip.height - 4))
            ?.key
            .naturalBelow,
        Pitch.parse('C5'),
      );
    });

    test('a tap outside the keyboard hits nothing', () {
      expect(layout.hitTest(const Offset(-5, 10)), isNull);
      expect(layout.hitTest(Offset(kTabletStrip.width + 5, 10)), isNull);
    });
  });

  group('interaction', () {
    testWidgets('pressing an active key reports it exactly once', (
      WidgetTester tester,
    ) async {
      final List<PianoKey> pressed = <PianoKey>[];
      await _pump(tester, kTabletStrip, kLevel1, pressed.add);

      final PianoKeyboardLayout layout = PianoKeyboardLayout(
        size: kTabletStrip,
      );
      final KeyPlacement middleC = layout.whiteKeys.firstWhere(
        (KeyPlacement p) => p.key.naturalBelow == Pitch.middleC,
      );
      final Offset origin = tester.getTopLeft(find.byType(PianoKeyboard));
      await tester.tapAt(
        origin + Offset(middleC.rect.center.dx, kTabletStrip.height - 6),
      );
      await tester.pumpAndSettle();

      expect(pressed, <PianoKey>[PianoKey.white(Pitch.middleC)]);
    });

    testWidgets('inactive keys swallow taps', (WidgetTester tester) async {
      final List<PianoKey> pressed = <PianoKey>[];
      await _pump(tester, kTabletStrip, kLevel1, pressed.add);

      final PianoKeyboardLayout layout = PianoKeyboardLayout(
        size: kTabletStrip,
      );
      final Offset origin = tester.getTopLeft(find.byType(PianoKeyboard));

      // A white key outside level 1.
      final KeyPlacement g4 = layout.whiteKeys.firstWhere(
        (KeyPlacement p) => p.key.naturalBelow == Pitch.parse('G4'),
      );
      await tester.tapAt(
        origin + Offset(g4.rect.center.dx, kTabletStrip.height - 6),
      );
      // And a black key, which is never active.
      await tester.tapAt(origin + layout.blackKeys.first.rect.center);
      await tester.pumpAndSettle();

      expect(pressed, isEmpty);
    });

    testWidgets('no key is labelled', (WidgetTester tester) async {
      await _pump(tester, kTabletStrip, kAllWhite, (PianoKey _) {});
      expect(
        find.descendant(
          of: find.byType(PianoKeyboard),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });
  });

  group('goldens', () {
    for (final MapEntry<String, Size> size in <String, Size>{
      'tablet': kTabletStrip,
      'phone': kPhoneStrip,
    }.entries) {
      testWidgets('golden: level-1 active on ${size.key}', (
        WidgetTester tester,
      ) async {
        await _pump(tester, size.value, kLevel1, (PianoKey _) {});
        await expectLater(
          find.byType(PianoKeyboard),
          matchesGoldenFile('goldens/keyboard-level1-${size.key}.png'),
        );
      });

      testWidgets('golden: all keys active on ${size.key}', (
        WidgetTester tester,
      ) async {
        await _pump(tester, size.value, kAllWhite, (PianoKey _) {});
        await expectLater(
          find.byType(PianoKeyboard),
          matchesGoldenFile('goldens/keyboard-all-${size.key}.png'),
        );
      });
    }
  });
  group('key model', () {
    test('a white key is its natural; a black key has no name yet', () {
      const PianoKey white = PianoKey.white(Pitch.middleC);
      const PianoKey black = PianoKey.black(Pitch.middleC);
      expect(white.pitch, Pitch.middleC);
      expect(white.isBlack, isFalse);
      // Unnamed by design: the same key is both a sharp and a flat, and
      // RFC-0001 defers that choice to level 9+.
      expect(black.pitch, isNull);
      expect(black.isBlack, isTrue);
    });

    test('white and black keys on the same natural are not equal', () {
      expect(
        const PianoKey.white(Pitch.middleC),
        isNot(const PianoKey.black(Pitch.middleC)),
      );
      expect(
        const PianoKey.white(Pitch.middleC),
        const PianoKey.white(Pitch.middleC),
      );
      expect(
        const PianoKey.white(Pitch.middleC).hashCode,
        const PianoKey.white(Pitch.middleC).hashCode,
      );
    });

    test('describes itself readably for test failures and logs', () {
      expect(const PianoKey.white(Pitch.middleC).toString(), 'C4');
      expect(const PianoKey.black(Pitch.middleC).toString(), 'black above C4');
    });

    test('knows which letters have a black key above them', () {
      expect(const PianoKey.white(Pitch.middleC).hasBlackAbove, isTrue);
      expect(PianoKey.white(Pitch.parse('E4')).hasBlackAbove, isFalse);
      expect(PianoKey.white(Pitch.parse('B3')).hasBlackAbove, isFalse);
    });
  });

  group('harness page', () {
    testWidgets('echoes the pressed key and can widen the active set', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: KeyboardHarnessPage()));
      await tester.pumpAndSettle();
      expect(find.text('Press a key'), findsOneWidget);

      // G4 is outside level 1, so pressing it does nothing...
      final Finder keyboard = find.byType(PianoKeyboard);
      final Rect box = tester.getRect(keyboard);
      final PianoKeyboardLayout layout = PianoKeyboardLayout(size: box.size);
      Offset at(String name) {
        final KeyPlacement p = layout.whiteKeys.firstWhere(
          (KeyPlacement k) => k.key.naturalBelow == Pitch.parse(name),
        );
        return box.topLeft + Offset(p.rect.center.dx, box.height - 6);
      }

      await tester.tapAt(at('G4'));
      await tester.pumpAndSettle();
      expect(find.text('Press a key'), findsOneWidget);

      // ...until every white key is switched on.
      await tester.tap(find.text('All white keys'));
      await tester.pumpAndSettle();
      await tester.tapAt(at('G4'));
      await tester.pumpAndSettle();
      expect(find.text('g'), findsOneWidget);
    });
  });
}
