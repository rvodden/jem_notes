import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';

DateTime day(int d) => DateTime(2026, 9, d);

RoundRecord round({
  int level = 1,
  int onDay = 1,
  int asked = 12,
  int correct = 12,
}) => RoundRecord(
  level: level,
  day: day(onDay),
  asked: asked,
  firstTimeCorrect: correct,
);

void main() {
  group('stars', () {
    test('three for a perfect round, two from 90%, one otherwise', () {
      expect(round(asked: 12, correct: 12).stars, 3);
      expect(round(asked: 10, correct: 9).stars, 2);
      expect(round(asked: 12, correct: 11).stars, 2);
      expect(round(asked: 12, correct: 10).stars, 1);
      expect(round(asked: 12, correct: 0).stars, 1);
    });

    test('measure accuracy, never speed', () {
      // There is no duration recorded anywhere in a RoundRecord, so stars
      // cannot accidentally become a race (RFC-0001: accuracy before speed).
      final Map<String, Object?> json = round().toJson();
      expect(json.keys, isNot(contains('duration')));
      expect(json.keys, isNot(contains('seconds')));
    });

    test('an empty round earns nothing rather than dividing by zero', () {
      expect(round(asked: 0, correct: 0).stars, 0);
      expect(round(asked: 0, correct: 0).accuracy, 0);
    });
  });

  group('streak counts days turned up, not answers got right', () {
    test('a bad round still extends the streak', () {
      // The point of D8: he showed up. A correctness streak would punish
      // exactly the stretch where he is slower with letter names.
      final Progress progress = Progress(
        rounds: <RoundRecord>[
          round(onDay: 1, asked: 12, correct: 0),
          round(onDay: 2, asked: 12, correct: 0),
        ],
      );
      expect(progress.streak, 2);
    });

    test('two rounds on the same day count once', () {
      final Progress progress = Progress(
        rounds: <RoundRecord>[round(onDay: 1), round(onDay: 1)],
      );
      expect(progress.streak, 1);
      expect(progress.practiceDays, <DateTime>[day(1)]);
    });

    test('consecutive days accumulate', () {
      final Progress progress = Progress(
        rounds: <RoundRecord>[
          round(onDay: 1),
          round(onDay: 2),
          round(onDay: 3),
        ],
      );
      expect(progress.streak, 3);
    });

    test('a gap resets it to the latest day alone', () {
      final Progress progress = Progress(
        rounds: <RoundRecord>[
          round(onDay: 1),
          round(onDay: 2),
          round(onDay: 5),
        ],
      );
      expect(progress.streak, 1);
    });

    test('no rounds means no streak', () {
      expect(const Progress().streak, 0);
    });
  });

  group('unlocking needs consistency across days (D6)', () {
    test('level 1 is always available', () {
      expect(const Progress().highestUnlockedLevel, 1);
      expect(const Progress().isUnlocked(1), isTrue);
      expect(const Progress().isUnlocked(2), isFalse);
    });

    test('one high-accuracy round is not enough', () {
      final Progress progress = Progress(
        rounds: <RoundRecord>[round(onDay: 1, asked: 12, correct: 12)],
      );
      expect(progress.highestUnlockedLevel, 1);
    });

    test('two high-accuracy rounds on the SAME day are not enough', () {
      // A six-year-old can have one good sitting; that is not the same as
      // having learned it.
      final Progress progress = Progress(
        rounds: <RoundRecord>[
          round(onDay: 1, asked: 12, correct: 12),
          round(onDay: 1, asked: 12, correct: 12),
        ],
      );
      expect(progress.highestUnlockedLevel, 1);
    });

    test('two high-accuracy rounds on two days unlock the next level', () {
      final Progress progress = Progress(
        rounds: <RoundRecord>[
          round(onDay: 1, asked: 12, correct: 12),
          round(onDay: 2, asked: 12, correct: 12),
        ],
      );
      expect(progress.highestUnlockedLevel, 2);
      expect(progress.isUnlocked(2), isTrue);
      expect(progress.isUnlocked(3), isFalse);
    });

    test('low-accuracy rounds never count toward unlocking', () {
      final Progress progress = Progress(
        rounds: <RoundRecord>[
          round(onDay: 1, asked: 12, correct: 8),
          round(onDay: 2, asked: 12, correct: 8),
          round(onDay: 3, asked: 12, correct: 8),
        ],
      );
      expect(progress.highestUnlockedLevel, 1);
    });

    test('unlocking is per level, not cumulative across the ladder', () {
      // Qualifying at level 1 opens level 2; it does not also open level 3.
      final Progress progress = Progress(
        rounds: <RoundRecord>[
          round(level: 1, onDay: 1),
          round(level: 1, onDay: 2),
          round(level: 2, onDay: 3),
        ],
      );
      expect(progress.highestUnlockedLevel, 2);
    });

    test('the ladder has a top', () {
      final List<RoundRecord> rounds = <RoundRecord>[];
      int d = 1;
      for (int level = 1; level <= Level.highestNumber + 2; level++) {
        rounds.add(round(level: level, onDay: d++));
        rounds.add(round(level: level, onDay: d++));
      }
      expect(
        Progress(rounds: rounds).highestUnlockedLevel,
        Level.highestNumber,
      );
    });
  });

  group('the level ladder', () {
    test('matches RFC-0001 and ends at the Book 2 range', () {
      expect(Level.ladder.length, 8);
      expect(Level.one.pitches.map((Pitch p) => p.scientificName), <String>[
        'B3',
        'C4',
        'D4',
      ]);
      expect(Level.byNumber(8)!.pitches.length, 15);
      expect(Level.byNumber(8)!.pitches.first, Pitch.parse('C3'));
      expect(Level.byNumber(8)!.pitches.last, Pitch.parse('C5'));
      expect(Level.byNumber(99), isNull);
    });

    test('every level widens or moves, never shrinks below three notes', () {
      for (final Level level in Level.ladder) {
        expect(
          level.pitches.length,
          greaterThanOrEqualTo(3),
          reason: 'level ${level.number}',
        );
      }
    });

    test('no level contains an accidental — those are level 9+', () {
      for (final Level level in Level.ladder) {
        for (final Pitch pitch in level.pitches) {
          expect(pitch.scientificName, matches(RegExp(r'^[A-G]-?\d+$')));
        }
      }
    });
  });

  group('persistence', () {
    test('survives a round trip through JSON', () {
      final Progress before = Progress(
        rounds: <RoundRecord>[round(onDay: 1), round(level: 2, onDay: 3)],
        pitchStats: <String, PitchStat>{
          'C4': const PitchStat(asked: 9, missed: 2),
        },
      );
      final Progress after = Progress.fromJson(
        jsonDecode(jsonEncode(before.toJson())) as Map<String, Object?>,
      );
      expect(after.rounds, before.rounds);
      expect(after.pitchStats, before.pitchStats);
      expect(after.streak, before.streak);
      expect(after.highestUnlockedLevel, before.highestUnlockedLevel);
    });

    test('reads an empty document as a fresh start', () {
      expect(Progress.fromJson(const <String, Object?>{}).rounds, isEmpty);
    });

    test('dayOf strips the time, so "today" is a calendar day', () {
      expect(
        dayOf(DateTime(2026, 9, 13, 23, 59)),
        dayOf(DateTime(2026, 9, 13, 0, 1)),
      );
    });
  });
}
