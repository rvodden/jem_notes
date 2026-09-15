import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';

const Size kTablet = Size(1024, 768);

/// Zero-length reveals keep the widget tests deterministic without waiting out
/// the real 1.1s pause.
Widget _app({int roundLength = 12, ProgressController? progress}) =>
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: ExercisePage(
        roundLength: roundLength,
        revealDuration: Duration.zero,
        progress: progress,
      ),
    );

Future<void> _pump(
  WidgetTester tester, {
  int roundLength = 12,
  ProgressController? progress,
}) async {
  tester.view.physicalSize = kTablet;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(roundLength: roundLength, progress: progress));
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
  await tester.tap(
    find.widgetWithText(FilledButton, pitch.letter.displayLabel),
  );
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
    await tester.tap(
      find.widgetWithText(FilledButton, wrongLetter.displayLabel),
    );
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
  testWidgets('the answer buttons are lower case', (WidgetTester tester) async {
    // A six-year-old reads lower case more fluently than capitals, so the
    // child-facing surface uses it even though note names are conventionally
    // capitals. The model keeps the canonical form — see Pitch.scientificName.
    await _pump(tester);
    await _tapKeyFor(tester, _shownPitch(tester));

    final List<String> labels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(FilledButton),
            matching: find.byType(Text),
          ),
        )
        .map((Text t) => t.data ?? '')
        .toList();

    expect(labels, hasLength(3));
    for (final String label in labels) {
      expect(
        label,
        label.toLowerCase(),
        reason: '"$label" should be lower case',
      );
      expect(
        RegExp(r'^[a-g]$').hasMatch(label),
        isTrue,
        reason: 'got "$label"',
      );
    }
    expect(labels.toSet(), <String>{'b', 'c', 'd'});
  });
  group('progress on the summary', () {
    Future<ProgressController> loaded({
      Progress seed = const Progress(),
      DateTime? today,
    }) async {
      final ProgressController controller = ProgressController(
        store: InMemoryProgressStore(seed),
        now: () => today ?? DateTime(2026, 9, 13),
      );
      await controller.load();
      return controller;
    }

    testWidgets('shows paw prints for the round just played', (
      WidgetTester tester,
    ) async {
      final ProgressController progress = await loaded();
      await _pump(tester, roundLength: 2, progress: progress);
      await _answerCorrectly(tester);
      await _answerCorrectly(tester);

      final List<PawPrint> paws = tester
          .widgetList<PawPrint>(find.byType(PawPrint))
          .toList();
      expect(paws, hasLength(3));
      expect(paws.every((PawPrint p) => p.filled), isTrue);
    });

    testWidgets('a missed note costs a paw but not the round', (
      WidgetTester tester,
    ) async {
      final ProgressController progress = await loaded();
      await _pump(tester, roundLength: 2, progress: progress);

      final Pitch first = _shownPitch(tester);
      await _tapKeyFor(tester, first);
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          Level.one.pitches
              .map((Pitch p) => p.letter)
              .firstWhere((NoteLetter l) => l != first.letter)
              .displayLabel,
        ),
      );
      await tester.pumpAndSettle();
      while (find.byType(StaffView).evaluate().isNotEmpty) {
        await _answerCorrectly(tester);
      }

      final List<PawPrint> paws = tester
          .widgetList<PawPrint>(find.byType(PawPrint))
          .toList();
      expect(paws.where((PawPrint p) => p.filled), hasLength(1));
      expect(paws.where((PawPrint p) => !p.filled), hasLength(2));
    });

    testWidgets('shows the streak in days, counting turning up', (
      WidgetTester tester,
    ) async {
      final ProgressController progress = await loaded(
        seed: Progress(
          rounds: <RoundRecord>[
            // Yesterday, and badly — it still counts toward the streak.
            RoundRecord(
              level: 1,
              day: DateTime(2026, 9, 12),
              asked: 12,
              firstTimeCorrect: 0,
            ),
          ],
        ),
      );
      await _pump(tester, roundLength: 2, progress: progress);
      await _answerCorrectly(tester);
      await _answerCorrectly(tester);

      expect(find.text('2 days in a row'), findsOneWidget);
    });

    testWidgets('no level chooser until there is a choice to make', (
      WidgetTester tester,
    ) async {
      final ProgressController progress = await loaded();
      await _pump(tester, roundLength: 2, progress: progress);
      await _answerCorrectly(tester);
      await _answerCorrectly(tester);

      expect(find.text('Level'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets('the chooser offers unlocked levels only', (
      WidgetTester tester,
    ) async {
      final ProgressController progress = await loaded(
        seed: Progress(
          rounds: <RoundRecord>[
            RoundRecord(
              level: 1,
              day: DateTime(2026, 9, 11),
              asked: 12,
              firstTimeCorrect: 12,
            ),
            RoundRecord(
              level: 1,
              day: DateTime(2026, 9, 12),
              asked: 12,
              firstTimeCorrect: 12,
            ),
          ],
        ),
      );
      expect(progress.highestUnlockedLevel, 2);

      await _pump(tester, roundLength: 2, progress: progress);
      await _answerCorrectly(tester);
      await _answerCorrectly(tester);

      expect(find.byType(ChoiceChip), findsNWidgets(2));
      expect(find.widgetWithText(ChoiceChip, '1'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '2'), findsOneWidget);
      // Locked levels are not rendered at all: nothing to tap hopefully.
      expect(find.widgetWithText(ChoiceChip, '3'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, '8'), findsNothing);
    });

    testWidgets('choosing a level starts a round at it', (
      WidgetTester tester,
    ) async {
      final ProgressController progress = await loaded(
        seed: Progress(
          rounds: <RoundRecord>[
            RoundRecord(
              level: 1,
              day: DateTime(2026, 9, 11),
              asked: 12,
              firstTimeCorrect: 12,
            ),
            RoundRecord(
              level: 1,
              day: DateTime(2026, 9, 12),
              asked: 12,
              firstTimeCorrect: 12,
            ),
          ],
        ),
      );
      await _pump(tester, roundLength: 2, progress: progress);
      await _answerCorrectly(tester);
      await _answerCorrectly(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, '1'));
      await tester.pumpAndSettle();

      // Back in a round, and restricted to level 1's three notes.
      expect(find.byType(StaffView), findsOneWidget);
      expect(Level.one.pitchSet, contains(_shownPitch(tester)));
    });
  });
  group('cats on the summary', () {
    Future<ProgressController> loadedWith(Progress seed, DateTime today) async {
      final ProgressController c = ProgressController(
        store: InMemoryProgressStore(seed),
        now: () => today,
      );
      await c.load();
      return c;
    }

    testWidgets('a companion cat is there from the very first round', (
      WidgetTester tester,
    ) async {
      final ProgressController progress = await loadedWith(
        const Progress(),
        DateTime(2026, 9, 13),
      );
      await _pump(tester, roundLength: 2, progress: progress);
      await _answerCorrectly(tester);
      await _answerCorrectly(tester);

      expect(find.text('Smudge'), findsOneWidget);
      expect(find.byType(CatView), findsWidgets);
    });

    testWidgets('a perfect round delights the companion', (
      WidgetTester tester,
    ) async {
      final ProgressController progress = await loadedWith(
        const Progress(),
        DateTime(2026, 9, 13),
      );
      await _pump(tester, roundLength: 2, progress: progress);
      await _answerCorrectly(tester);
      await _answerCorrectly(tester);

      final CatView companion = tester
          .widgetList<CatView>(find.byType(CatView))
          .firstWhere((CatView c) => c.size > 100);
      expect(companion.mood, CatMood.delighted);
    });

    testWidgets('a bad round leaves the companion pleased, never worse', (
      WidgetTester tester,
    ) async {
      final ProgressController progress = await loadedWith(
        const Progress(),
        DateTime(2026, 9, 13),
      );
      await _pump(tester, roundLength: 2, progress: progress);

      // Miss both questions outright.
      for (int i = 0; i < 2; i++) {
        final Pitch shown = _shownPitch(tester);
        await _tapKeyFor(tester, shown);
        await tester.tap(
          find.widgetWithText(
            FilledButton,
            Level.one.pitches
                .map((Pitch p) => p.letter)
                .firstWhere((NoteLetter l) => l != shown.letter)
                .displayLabel,
          ),
        );
        await tester.pumpAndSettle();
      }
      while (find.byType(StaffView).evaluate().isNotEmpty) {
        await _answerCorrectly(tester);
      }

      final CatView companion = tester
          .widgetList<CatView>(find.byType(CatView))
          .firstWhere((CatView c) => c.size > 100);
      expect(
        companion.mood,
        CatMood.pleased,
        reason: 'there is no mood that could look disappointed in him',
      );
    });

    testWidgets('meeting a new cat is announced by name and reason', (
      WidgetTester tester,
    ) async {
      // One day short of the two-day streak cat; this round earns it.
      final ProgressController progress = await loadedWith(
        Progress(
          rounds: <RoundRecord>[
            RoundRecord(
              level: 1,
              day: DateTime(2026, 9, 12),
              asked: 12,
              firstTimeCorrect: 4,
            ),
          ],
        ),
        DateTime(2026, 9, 13),
      );
      await _pump(tester, roundLength: 2, progress: progress);
      await _answerCorrectly(tester);
      await _answerCorrectly(tester);

      expect(find.text('You met Biscuit!'), findsOneWidget);
      expect(find.text('For practising 2 days in a row'), findsOneWidget);
    });

    testWidgets('the collection shows met and unmet, and what comes next', (
      WidgetTester tester,
    ) async {
      final ProgressController progress = await loadedWith(
        const Progress(),
        DateTime(2026, 9, 13),
      );
      await _pump(tester, roundLength: 2, progress: progress);
      await _answerCorrectly(tester);
      await _answerCorrectly(tester);

      expect(
        find.text('Your cats — 1 of ${CatCatalogue.all.length}'),
        findsOneWidget,
      );
      // Unmet cats are drawn as silhouettes rather than hidden, so he can see
      // how many friends are still out there.
      final List<CatView> shown = tester
          .widgetList<CatView>(find.byType(CatView))
          .where((CatView c) => c.size < 60)
          .toList();
      expect(shown, hasLength(CatCatalogue.all.length));
      expect(shown.where((CatView c) => c.faded), isNotEmpty);
      expect(find.textContaining('Next friend:'), findsOneWidget);
    });
  });
  group('the progress trail', () {
    testWidgets('is a paw print per question, filling as he goes', (
      WidgetTester tester,
    ) async {
      await _pump(tester, roundLength: 4);

      List<PawPrint> paws() =>
          tester.widgetList<PawPrint>(find.byType(PawPrint)).toList();

      expect(paws(), hasLength(4), reason: 'one per question in the round');
      expect(
        paws().where((PawPrint p) => p.filled),
        isEmpty,
        reason: 'nothing done yet on the first question',
      );

      await _answerCorrectly(tester);
      expect(paws().where((PawPrint p) => p.filled), hasLength(1));

      await _answerCorrectly(tester);
      expect(paws().where((PawPrint p) => p.filled), hasLength(2));
    });

    testWidgets('shows no number and no clock', (WidgetTester tester) async {
      await _pump(tester, roundLength: 12);
      // A fraction like "4 / 12" invites hurrying, which is the opposite of
      // what this exercise wants while accuracy is still being built.
      final Iterable<String> texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? '');
      for (final String text in texts) {
        expect(RegExp(r'\d').hasMatch(text), isFalse, reason: 'found "$text"');
      }
    });
  });
}
