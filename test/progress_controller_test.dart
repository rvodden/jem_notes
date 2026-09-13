import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';
import 'package:jem_notes/main.dart';

/// Plays a whole round against the model, answering every question correctly.
void playPerfectRound(ExerciseRound round) {
  while (!round.isComplete) {
    final Question q = round.current!;
    round.submitKey(PianoKey.white(q.pitch));
    round.submitLetter(q.pitch.letter);
  }
}

/// Plays a round, always naming [victim] wrongly.
void playMissing(ExerciseRound round, Pitch victim) {
  while (!round.isComplete) {
    final Question q = round.current!;
    round.submitKey(PianoKey.white(q.pitch));
    if (q.pitch == victim) {
      round.submitLetter(
        round.level.pitches
            .map((Pitch p) => p.letter)
            .firstWhere((NoteLetter l) => l != q.pitch.letter),
      );
      round.dismissReveal();
    } else {
      round.submitLetter(q.pitch.letter);
    }
  }
}

void main() {
  group('recording a round', () {
    test('stores it, awards stars, and starts a streak', () async {
      final ProgressController controller = ProgressController(
        store: InMemoryProgressStore(),
        now: () => DateTime(2026, 9, 13, 17, 30),
      );
      await controller.load();

      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 6,
        random: Random(1),
      );
      playPerfectRound(round);
      final RoundRecord record = await controller.recordRound(round);

      expect(record.stars, 3);
      expect(record.asked, 6);
      expect(record.day, DateTime(2026, 9, 13));
      expect(controller.streak, 1);
      expect(controller.progress.rounds, hasLength(1));
    });

    test('per-note history accumulates across rounds', () async {
      final ProgressController controller = ProgressController(
        store: InMemoryProgressStore(),
        now: () => DateTime(2026, 9, 13),
      );
      await controller.load();

      for (int i = 0; i < 2; i++) {
        final ExerciseRound round = ExerciseRound(
          level: Level.one,
          roundLength: 6,
          random: Random(i + 1),
        );
        playMissing(round, Pitch.middleC);
        await controller.recordRound(round);
      }

      final PitchStat stat = controller.progress.pitchStats['C4']!;
      expect(stat.asked, greaterThan(0));
      expect(stat.missed, greaterThan(0));
      // And it feeds back into the next round's weighting, so a note he
      // struggled with yesterday still comes round more often today.
      expect(controller.missCountsFor(Level.one)[Pitch.middleC], stat.missed);
    });

    test(
      'a missed note counts once per question, not once per fumbled tap',
      () async {
        final ProgressController controller = ProgressController(
          store: InMemoryProgressStore(),
          now: () => DateTime(2026, 9, 13),
        );
        await controller.load();

        final ExerciseRound round = ExerciseRound(
          level: Level.one,
          roundLength: 1,
          random: Random(3),
        );
        final Pitch shown = round.current!.pitch;
        final Pitch other = Level.one.pitches.firstWhere(
          (Pitch p) => p != shown,
        );
        // Wrong key AND wrong name on the same question.
        round.submitKey(PianoKey.white(other));
        round.dismissReveal();
        round.submitLetter(
          Level.one.pitches
              .map((Pitch p) => p.letter)
              .firstWhere((NoteLetter l) => l != shown.letter),
        );
        round.dismissReveal();
        while (!round.isComplete) {
          final Question q = round.current!;
          round.submitKey(PianoKey.white(q.pitch));
          round.submitLetter(q.pitch.letter);
        }
        await controller.recordRound(round);

        expect(controller.progress.pitchStats[shown.scientificName]!.missed, 1);
      },
    );
  });

  group('unlocking through the controller', () {
    test('needs two good rounds on two different days', () async {
      DateTime today = DateTime(2026, 9, 13);
      final ProgressController controller = ProgressController(
        store: InMemoryProgressStore(),
        now: () => today,
      );
      await controller.load();

      Future<void> perfectRound() async {
        final ExerciseRound round = ExerciseRound(
          level: Level.byNumber(controller.highestUnlockedLevel)!,
          roundLength: 6,
          random: Random(2),
        );
        playPerfectRound(round);
        await controller.recordRound(round);
      }

      await perfectRound();
      expect(controller.highestUnlockedLevel, 1);
      await perfectRound();
      expect(controller.highestUnlockedLevel, 1, reason: 'same day');

      today = DateTime(2026, 9, 14);
      await perfectRound();
      expect(controller.highestUnlockedLevel, 2);
      expect(controller.unlockedLevels.map((Level l) => l.number), <int>[1, 2]);
    });
  });

  group('persistence', () {
    test('progress survives a restart', () async {
      final InMemoryProgressStore store = InMemoryProgressStore();
      final ProgressController first = ProgressController(
        store: store,
        now: () => DateTime(2026, 9, 13),
      );
      await first.load();
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 6,
        random: Random(1),
      );
      playPerfectRound(round);
      await first.recordRound(round);

      // A new controller over the same store is what a restart looks like.
      final ProgressController second = ProgressController(store: store);
      await second.load();
      expect(second.progress.rounds, hasLength(1));
      expect(second.streak, 1);
      expect(second.progress.pitchStats, isNotEmpty);
    });
  });

  group('nothing leaves the device', () {
    testWidgets('the app makes no network calls', (WidgetTester tester) async {
      // RFC-0001 D10: single learner, offline, no accounts. Enforced rather
      // than intended — any attempt to create an HTTP client fails the test,
      // which also guards against a dependency quietly phoning home.
      final HttpOverrides? previous = HttpOverrides.current;
      HttpOverrides.global = _NoNetworkAllowed();
      addTearDown(() => HttpOverrides.global = previous);

      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final ProgressController controller = ProgressController(
        store: InMemoryProgressStore(),
      );
      await tester.pumpWidget(JemNotesApp(progress: controller));
      await tester.pumpAndSettle();

      // Play a full question, the most network-tempting moment there is.
      final Pitch pitch = tester
          .widget<StaffView>(find.byType(StaffView))
          .pitch;
      final Rect box = tester.getRect(find.byType(PianoKeyboard));
      final PianoKeyboardLayout layout = PianoKeyboardLayout(size: box.size);
      final KeyPlacement placement = layout.whiteKeys.firstWhere(
        (KeyPlacement p) => p.key.naturalBelow == pitch,
      );
      await tester.tapAt(
        box.topLeft + Offset(placement.rect.center.dx, box.height - 8),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, pitch.letter.displayLabel),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// Fails loudly if anything tries to open a network connection.
class _NoNetworkAllowed extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('the app must make no network calls (RFC-0001 D10)');
  }
}
