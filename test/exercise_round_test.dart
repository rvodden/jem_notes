import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';

/// Answers the current question correctly, both halves.
void answerCorrectly(ExerciseRound round) {
  final Question q = round.current!;
  round.submitKey(PianoKey.white(q.pitch));
  round.submitLetter(q.pitch.letter);
}

/// Gets the key right, then deliberately names it wrong.
void answerNameWrong(ExerciseRound round) {
  final Question q = round.current!;
  round.submitKey(PianoKey.white(q.pitch));
  final NoteLetter wrong = round.level.pitches
      .map((Pitch p) => p.letter)
      .firstWhere((NoteLetter l) => l != q.pitch.letter);
  round.submitLetter(wrong);
  round.dismissReveal();
}

void main() {
  group('a clean round', () {
    test('asks exactly the round length and ends complete', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 12,
        random: Random(1),
      );
      int asked = 0;
      while (!round.isComplete) {
        asked++;
        answerCorrectly(round);
      }
      expect(asked, 12);
      expect(round.summary.asked, 12);
      expect(round.summary.firstTimeCorrect, 12);
    });

    test('only asks notes from the level', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        random: Random(7),
      );
      while (!round.isComplete) {
        expect(Level.one.pitchSet, contains(round.current!.pitch));
        answerCorrectly(round);
      }
    });

    test('never asks the same note twice running', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 40,
        random: Random(3),
      );
      Pitch? previous;
      while (!round.isComplete) {
        final Pitch pitch = round.current!.pitch;
        expect(pitch, isNot(previous));
        previous = pitch;
        answerCorrectly(round);
      }
    });
  });

  group('two steps, in order', () {
    test('a correct key advances to naming without ending the question', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        random: Random(1),
      );
      final Question q = round.current!;
      expect(round.step, AnswerStep.locate);
      round.submitKey(PianoKey.white(q.pitch));
      expect(round.step, AnswerStep.name);
      expect(round.current, q, reason: 'same question, second half');
    });

    test('a wrong key reveals the right one and still proceeds to naming', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        random: Random(1),
      );
      final Question q = round.current!;
      final Pitch other = Level.one.pitches.firstWhere(
        (Pitch p) => p != q.pitch,
      );

      round.submitKey(PianoKey.white(other));
      expect(round.reveal, Reveal.correctKey);
      expect(round.expectedPitch, q.pitch);
      // Getting the key wrong must not cost him the chance to name the note.
      round.dismissReveal();
      expect(round.step, AnswerStep.name);
      expect(round.current, q);
    });

    test('input is ignored while the answer is being revealed', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        random: Random(1),
      );
      final Question q = round.current!;
      final Pitch other = Level.one.pitches.firstWhere(
        (Pitch p) => p != q.pitch,
      );
      round.submitKey(PianoKey.white(other));
      round.submitKey(PianoKey.white(q.pitch)); // should do nothing
      expect(round.reveal, Reveal.correctKey);
      expect(round.step, AnswerStep.locate);
    });

    test('a black key is never a valid answer', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        random: Random(1),
      );
      final Question q = round.current!;
      round.submitKey(PianoKey.black(q.pitch));
      expect(round.reveal, Reveal.correctKey, reason: 'counted as a miss');
    });
  });

  group('missed notes come back', () {
    test('a note named wrongly is asked again before the round ends', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 12,
        random: Random(5),
      );
      final Pitch missed = round.current!.pitch;
      answerNameWrong(round);

      bool askedAgain = false;
      while (!round.isComplete) {
        if (round.current!.pitch == missed) askedAgain = true;
        answerCorrectly(round);
      }
      expect(askedAgain, isTrue);
    });

    test('a miss on the final question extends the round rather than '
        'dropping the re-ask', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 3,
        random: Random(11),
      );
      answerCorrectly(round);
      answerCorrectly(round);
      // Third and final scheduled question — miss it.
      final Pitch missed = round.current!.pitch;
      answerNameWrong(round);

      expect(round.isComplete, isFalse, reason: 'the re-ask must still happen');
      expect(round.current!.pitch, missed);
      answerCorrectly(round);
      expect(round.isComplete, isTrue);
      expect(round.summary.asked, 4);
    });

    test('a missed question does not count as first-time-correct', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 4,
        random: Random(2),
      );
      answerNameWrong(round);
      while (!round.isComplete) {
        answerCorrectly(round);
      }
      expect(round.summary.firstTimeCorrect, lessThan(round.summary.asked));
    });
  });

  group('middle C is written both ways', () {
    test('both clefs appear across a long enough run', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 200,
        random: Random(4),
      );
      final Set<Clef> clefsForMiddleC = <Clef>{};
      while (!round.isComplete) {
        final Question q = round.current!;
        if (q.pitch == Pitch.middleC) clefsForMiddleC.add(q.clef);
        answerCorrectly(round);
      }
      expect(clefsForMiddleC, <Clef>{Clef.treble, Clef.bass});
    });

    test('other notes always use their natural clef', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 120,
        random: Random(9),
      );
      while (!round.isComplete) {
        final Question q = round.current!;
        if (q.pitch != Pitch.middleC) {
          expect(q.clef, StaffGeometry.defaultClefFor(q.pitch));
        }
        answerCorrectly(round);
      }
    });
  });

  group('weighting toward missed notes (D7)', () {
    test('a note always answered wrongly is asked measurably more often', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 200,
        random: Random(13),
      );
      // Pick a victim up front and always get it wrong.
      const Pitch victim = Pitch.middleC;
      final Map<Pitch, int> asked = <Pitch, int>{};

      while (!round.isComplete) {
        final Question q = round.current!;
        asked[q.pitch] = (asked[q.pitch] ?? 0) + 1;
        if (q.pitch == victim) {
          answerNameWrong(round);
        } else {
          answerCorrectly(round);
        }
      }

      final int victimCount = asked[victim] ?? 0;
      for (final Pitch other in Level.one.pitches.where(
        (Pitch p) => p != victim,
      )) {
        expect(
          victimCount,
          greaterThan(asked[other] ?? 0),
          reason: 'the note he keeps missing should come round more often',
        );
      }
      // An even split over three notes would be a third; weighting should be
      // clearly above that, while the no-repeats rule caps it below half.
      expect(victimCount / round.summary.asked, greaterThan(0.33));
      expect(victimCount / round.summary.asked, lessThanOrEqualTo(0.5));
    });
  });

  group('selector', () {
    test('weight rises with misses and falls again with correct answers', () {
      final PitchSelector selector = PitchSelector(
        pitches: Level.one.pitches,
        random: Random(1),
      );
      expect(selector.weightOf(Pitch.middleC), 1);
      selector.recordMiss(Pitch.middleC);
      selector.recordMiss(Pitch.middleC);
      expect(selector.weightOf(Pitch.middleC), 3);
      selector.recordCorrect(Pitch.middleC);
      expect(selector.weightOf(Pitch.middleC), 2);
    });

    test('the miss bonus is capped so one note cannot crowd out the rest', () {
      final PitchSelector selector = PitchSelector(
        pitches: Level.one.pitches,
        random: Random(1),
      );
      for (int i = 0; i < 50; i++) {
        selector.recordMiss(Pitch.middleC);
      }
      expect(selector.weightOf(Pitch.middleC), 4);
    });

    test('correct answers never push weight below the baseline', () {
      final PitchSelector selector = PitchSelector(
        pitches: Level.one.pitches,
        random: Random(1),
      );
      for (int i = 0; i < 10; i++) {
        selector.recordCorrect(Pitch.middleC);
      }
      expect(selector.weightOf(Pitch.middleC), 1);
    });

    test('rejects an empty note set rather than failing later', () {
      expect(
        () => PitchSelector(pitches: const <Pitch>[]),
        throwsArgumentError,
      );
    });

    test(
      'a single-note level repeats that note, repeat rule notwithstanding',
      () {
        final PitchSelector selector = PitchSelector(
          pitches: <Pitch>[Pitch.middleC],
          random: Random(1),
        );
        expect(selector.next(), Pitch.middleC);
        expect(selector.next(), Pitch.middleC);
      },
    );
  });
  group('a round always ends', () {
    test('even when every single answer is wrong', () {
      // Regression: an uncapped re-ask extension made this loop forever, which
      // would have trapped exactly the child who is struggling most. The round
      // must terminate no matter how badly it goes.
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 12,
        random: Random(17),
      );
      int guard = 0;
      while (!round.isComplete) {
        if (++guard > 100) {
          fail('round did not terminate after $guard questions');
        }
        final Question q = round.current!;
        final Pitch wrongKey = Level.one.pitches.firstWhere(
          (Pitch p) => p != q.pitch,
        );
        round.submitKey(PianoKey.white(wrongKey));
        round.dismissReveal();
        final NoteLetter wrongName = Level.one.pitches
            .map((Pitch p) => p.letter)
            .firstWhere((NoteLetter l) => l != q.pitch.letter);
        round.submitLetter(wrongName);
        round.dismissReveal();
      }
      expect(round.summary.firstTimeCorrect, 0);
      // 12 scheduled, plus at most one extra pass over the level's three notes.
      expect(round.summary.asked, lessThanOrEqualTo(15));
      expect(round.summary.asked, greaterThanOrEqualTo(12));
    });

    test('an all-correct round is never extended', () {
      final ExerciseRound round = ExerciseRound(
        level: Level.one,
        roundLength: 12,
        random: Random(19),
      );
      while (!round.isComplete) {
        answerCorrectly(round);
      }
      expect(round.summary.asked, 12);
    });
  });
}
