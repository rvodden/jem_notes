import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';

const Size kTablet = Size(1024, 768);

/// Zero-length reveals keep the widget tests deterministic without waiting out
/// the real 1.1s pause.
Widget _app({int roundLength = 12}) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: ExercisePage(roundLength: roundLength, revealDuration: Duration.zero),
);

Future<void> _pump(WidgetTester tester, {int roundLength = 12}) async {
  tester.view.physicalSize = kTablet;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(roundLength: roundLength));
  await tester.pumpAndSettle();
}

/// Which note is on screen, read off the rendered staff.
Pitch _shownPitch(WidgetTester tester) =>
    tester.widget<StaffView>(find.byType(StaffView)).pitch;

Future<void> _tapKeyFor(WidgetTester tester, Pitch pitch) async {
  final Rect box = tester.getRect(find.byType(PianoKeyboard));
  final PianoKeyboardLayout layout = PianoKeyboardLayout(size: box.size);
  final KeyPlacement placement = layout.whiteKeys.firstWhere(
    (KeyPlacement p) => p.key.naturalBelow == pitch,
  );
  await tester.tapAt(
    box.topLeft + Offset(placement.rect.center.dx, box.height - 8),
  );
  await tester.pumpAndSettle();
}

/// One complete question, answered correctly.
Future<void> _answerCorrectly(WidgetTester tester) async {
  final Pitch pitch = _shownPitch(tester);
  await _tapKeyFor(tester, pitch);
  await tester.tap(find.widgetWithText(FilledButton, pitch.letter.label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens straight into a round, with no menu to get past', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    expect(find.byType(StaffView), findsOneWidget);
    expect(find.byType(PianoKeyboard), findsOneWidget);
    expect(find.text('Find it on the keyboard'), findsOneWidget);
  });

  testWidgets('asks for the key first, then the letter name', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    // No letter buttons until the key has been located.
    expect(find.byType(FilledButton), findsNothing);

    final Pitch pitch = _shownPitch(tester);
    await _tapKeyFor(tester, pitch);

    expect(find.text('Find it on the keyboard'), findsNothing);
    expect(find.byType(FilledButton), findsNWidgets(3));
    // Still the same note: locating it did not end the question.
    expect(_shownPitch(tester), pitch);
  });

  testWidgets('a wrong key reveals the right one and moves on to naming', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    final Pitch shown = _shownPitch(tester);
    final Pitch wrong = Level.one.pitches.firstWhere((Pitch p) => p != shown);

    await _tapKeyFor(tester, wrong);
    // revealDuration is zero, so by now the reveal has already elapsed.
    expect(find.byType(FilledButton), findsNWidgets(3));
    expect(_shownPitch(tester), shown);
  });

  testWidgets('a full round ends on a summary, which can start another', (
    WidgetTester tester,
  ) async {
    await _pump(tester, roundLength: 12);
    for (int i = 0; i < 12; i++) {
      await _answerCorrectly(tester);
    }

    expect(find.text('Well done'), findsOneWidget);
    expect(find.text('You got 12 of 12 right first time.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Go again'));
    await tester.pumpAndSettle();
    expect(find.byType(StaffView), findsOneWidget);
    expect(find.text('Well done'), findsNothing);
  });

  testWidgets('the summary counts only first-time-correct answers', (
    WidgetTester tester,
  ) async {
    await _pump(tester, roundLength: 3);

    // Miss the first question's name, answer the rest cleanly.
    final Pitch first = _shownPitch(tester);
    await _tapKeyFor(tester, first);
    final NoteLetter wrongLetter = Level.one.pitches
        .map((Pitch p) => p.letter)
        .firstWhere((NoteLetter l) => l != first.letter);
    await tester.tap(find.widgetWithText(FilledButton, wrongLetter.label));
    await tester.pumpAndSettle();

    while (find.byType(StaffView).evaluate().isNotEmpty) {
      await _answerCorrectly(tester);
    }

    // The round stays 3 questions: the miss on the first is re-asked inside
    // the remaining slots rather than extending the round.
    expect(find.textContaining('You got 2 of 3'), findsOneWidget);
  });

  testWidgets('shows no clock, no score and no finger numbers', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    // Walk the whole visible text of a question for anything resembling a
    // countdown, a running score, or a fingering digit.
    final Iterable<String> texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text t) => t.data ?? '')
        .where((String s) => s.isNotEmpty);

    for (final String text in texts) {
      expect(
        RegExp(r'\d').hasMatch(text),
        isFalse,
        reason: 'no digits belong on a question screen, found: "$text"',
      );
    }
    expect(find.byIcon(Icons.timer), findsNothing);
  });

  testWidgets('golden: locate step', (WidgetTester tester) async {
    await _pump(tester);
    await expectLater(
      find.byType(ExercisePage),
      matchesGoldenFile('goldens/exercise-locate.png'),
    );
  });

  testWidgets('golden: name step', (WidgetTester tester) async {
    await _pump(tester);
    await _tapKeyFor(tester, _shownPitch(tester));
    await expectLater(
      find.byType(ExercisePage),
      matchesGoldenFile('goldens/exercise-name.png'),
    );
  });

  testWidgets('golden: summary', (WidgetTester tester) async {
    await _pump(tester, roundLength: 2);
    await _answerCorrectly(tester);
    await _answerCorrectly(tester);
    await expectLater(
      find.byType(ExercisePage),
      matchesGoldenFile('goldens/exercise-summary.png'),
    );
  });
}
