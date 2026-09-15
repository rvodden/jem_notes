import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';

void main() {
  group('no cat is ever sad', () {
    test('the mood enum has no state that could express disappointment', () {
      // DEC-0007, enforced structurally rather than by intention. "You made
      // Duo sad" is the canonical guilt lever, and the documented harm is that
      // children end up managing anxiety rather than learning. A sad cat is
      // unrepresentable here, the same way RoundRecord has no duration field.
      expect(CatMood.values, <CatMood>[
        CatMood.pleased,
        CatMood.delighted,
        CatMood.sleepy,
      ]);
      for (final CatMood mood in CatMood.values) {
        expect(<String>[
          'sad',
          'disappointed',
          'angry',
          'crying',
          'waiting',
        ], isNot(contains(mood.name)));
      }
    });
  });

  group('earning cats', () {
    test('he starts with one — nobody begins with nothing', () {
      final List<CatReward> cats = CatCatalogue.earned(
        highestLevel: 1,
        longestStreak: 0,
      );
      expect(cats, hasLength(1));
      expect(cats.single.source, CatSource.start);
      expect(cats.single.cat.name, 'Smudge');
    });

    test('turning up earns cats even when the reading goes badly', () {
      // The whole point of having two sources: cats tied only to levels would
      // leave the struggling child — the one who needs the pull most — with
      // nothing at all.
      final List<CatReward> cats = CatCatalogue.earned(
        highestLevel: 1,
        longestStreak: 7,
      );
      expect(cats.length, greaterThan(1));
      expect(
        cats.where((CatReward r) => r.source == CatSource.streak),
        isNotEmpty,
      );
    });

    test('reading further earns cats too', () {
      final List<CatReward> cats = CatCatalogue.earned(
        highestLevel: 4,
        longestStreak: 0,
      );
      expect(
        cats.where((CatReward r) => r.source == CatSource.level).length,
        3,
        reason: 'levels 2, 3 and 4',
      );
    });

    test(
      'every cat is reachable, and the last needs the top of the ladder',
      () {
        final List<CatReward> all = CatCatalogue.earned(
          highestLevel: 8,
          longestStreak: 30,
        );
        expect(all, hasLength(CatCatalogue.all.length));
        expect(CatCatalogue.next(highestLevel: 8, longestStreak: 30), isNull);
      },
    );

    test('the next cat is the closest one, not the next in the list', () {
      // Level 2 reached, an eight-day best streak: the level-3 cat is one step
      // away, the 14-day cat is six. Offering the distant one would be worse
      // than saying nothing.
      final CatReward? next = CatCatalogue.next(
        highestLevel: 2,
        longestStreak: 8,
      );
      expect(next, isNotNull);
      expect(next!.hint, 'Reach level 3');
    });

    test('a long streak but an early level points at the next level', () {
      final CatReward? next = CatCatalogue.next(
        highestLevel: 1,
        longestStreak: 30,
      );
      expect(next!.source, CatSource.level);
      expect(next.hint, 'Reach level 2');
    });

    test('a high level but no streak points at practising', () {
      final CatReward? next = CatCatalogue.next(
        highestLevel: 8,
        longestStreak: 0,
      );
      expect(next!.source, CatSource.streak);
      expect(next.hint, 'Practise 2 days in a row');
    });

    test('cats have distinct ids and names', () {
      expect(
        CatCatalogue.all.map((CatReward r) => r.cat.id).toSet(),
        hasLength(CatCatalogue.all.length),
      );
      expect(
        CatCatalogue.all.map((CatReward r) => r.cat.name).toSet(),
        hasLength(CatCatalogue.all.length),
      );
    });

    test('hints tell him what to do, descriptions say what happened', () {
      final CatReward marmalade = CatCatalogue.all.firstWhere(
        (CatReward r) => r.cat.id == 'marmalade',
      );
      expect(marmalade.hint, 'Practise 7 days in a row');
      expect(marmalade.description, 'For practising 7 days in a row');
      final CatReward socks = CatCatalogue.all.firstWhere(
        (CatReward r) => r.cat.id == 'socks',
      );
      expect(socks.hint, 'Reach level 2');
      for (final CatReward reward in CatCatalogue.all) {
        expect(reward.hint, isNotEmpty);
        expect(reward.hint, isNot(contains('null')));
      }
    });

    test('each reward explains itself in words a child could read', () {
      for (final CatReward reward in CatCatalogue.all) {
        expect(reward.description, isNotEmpty);
        expect(reward.description, isNot(contains('null')));
      }
      expect(
        CatCatalogue.all
            .firstWhere((CatReward r) => r.cat.id == 'marmalade')
            .description,
        'For practising 7 days in a row',
      );
    });
  });

  group('a cat is never taken away', () {
    test('breaking a streak loses the number, not the friend', () {
      // Earned against the LONGEST streak ever, not the current one.
      final Progress onAGoodRun = Progress(
        rounds: <RoundRecord>[
          for (int d = 1; d <= 8; d++)
            RoundRecord(
              level: 1,
              day: DateTime(2026, 9, d),
              asked: 12,
              firstTimeCorrect: 6,
            ),
        ],
      );
      expect(onAGoodRun.streak, 8);
      expect(onAGoodRun.longestStreak, 8);
      final int had = CatCatalogue.earned(
        highestLevel: onAGoodRun.highestUnlockedLevel,
        longestStreak: onAGoodRun.longestStreak,
      ).length;

      // Two weeks off, then one round back.
      final Progress afterABreak = Progress(
        rounds: <RoundRecord>[
          ...onAGoodRun.rounds,
          RoundRecord(
            level: 1,
            day: DateTime(2026, 9, 25),
            asked: 12,
            firstTimeCorrect: 6,
          ),
        ],
      );
      expect(afterABreak.streak, 1, reason: 'the number resets');
      expect(afterABreak.longestStreak, 8, reason: 'the record does not');
      expect(
        CatCatalogue.earned(
          highestLevel: afterABreak.highestUnlockedLevel,
          longestStreak: afterABreak.longestStreak,
        ).length,
        had,
        reason: 'and neither do the cats',
      );
    });

    test('longest streak survives gaps on both sides', () {
      final Progress progress = Progress(
        rounds: <RoundRecord>[
          for (final int d in <int>[1, 2, 3, 4, 9, 20, 21])
            RoundRecord(
              level: 1,
              day: DateTime(2026, 9, d),
              asked: 12,
              firstTimeCorrect: 12,
            ),
        ],
      );
      expect(progress.longestStreak, 4);
      expect(progress.streak, 2);
    });

    test('no rounds, no streak, but still the starter cat', () {
      const Progress fresh = Progress();
      expect(fresh.longestStreak, 0);
      expect(
        CatCatalogue.earned(
          highestLevel: fresh.highestUnlockedLevel,
          longestStreak: fresh.longestStreak,
        ),
        hasLength(1),
      );
    });
  });
}
