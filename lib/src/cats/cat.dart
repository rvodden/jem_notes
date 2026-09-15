import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// How a cat is feeling.
///
/// **There is deliberately no sad, disappointed or waiting state, and there
/// never should be** (DEC-0007). Duolingo's "You made Duo sad" is the canonical
/// example of a mascot used as a guilt lever, and the documented harm is not
/// that it is unpleasant but that children end up *managing anxiety* — picking
/// the easiest lesson to protect a number rather than to learn anything.
///
/// This app's whole design avoids that: the streak counts turning up rather
/// than being right, there is no clock and no red X. One disappointed cat face
/// would undo all of it. Making the state unrepresentable is the same technique
/// as [RoundRecord] carrying no duration field — the type system refuses rather
/// than relying on nobody adding it later.
enum CatMood {
  /// Default: eyes open, small smile.
  pleased,

  /// Eyes squeezed happily shut. For a perfect round, or a new cat arriving.
  delighted,

  /// Half-closed eyes. Purely decorative variety, never a comment on him.
  sleepy,
}

/// How a cat is marked.
enum CatPattern { plain, tabby, patch, tuxedo, mitts }

/// One cat.
@immutable
class Cat {
  const Cat({
    required this.id,
    required this.name,
    required this.coat,
    required this.marking,
    required this.pattern,
    required this.eyes,
  });

  /// Stable identifier, used to remember which cats have been met.
  final String id;

  /// What he calls it.
  final String name;

  final Color coat;
  final Color marking;
  final CatPattern pattern;
  final Color eyes;

  @override
  bool operator ==(Object other) => other is Cat && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

/// How a cat is earned.
enum CatSource { start, level, streak }

/// A cat, and what it takes to meet it.
@immutable
class CatReward {
  const CatReward({
    required this.cat,
    required this.source,
    required this.threshold,
  });

  final Cat cat;
  final CatSource source;

  /// The level reached, or the streak length, that brings this cat. Zero for
  /// the cat he starts with.
  final int threshold;

  /// Why a cat he has just met arrived. Past tense — it already happened.
  String get description => switch (source) {
    CatSource.start => 'Here from the start',
    CatSource.level => 'For reaching level $threshold',
    CatSource.streak => 'For practising $threshold days in a row',
  };

  /// What to do to meet a cat he has not met yet. An instruction, not a
  /// description — it tells him what is within reach rather than restating a
  /// rule he would have to decode.
  String get hint => switch (source) {
    CatSource.start => 'Already here',
    CatSource.level => 'Reach level $threshold',
    CatSource.streak => 'Practise $threshold days in a row',
  };
}

/// Every cat, and what brings it.
///
/// Two sources, deliberately (DEC-0007). Cats from levels alone would invert
/// the encouragement — the child who is struggling, who needs the pull most,
/// would earn nothing. Streak cats mean **turning up always earns cats**,
/// however the reading is going.
class CatCatalogue {
  const CatCatalogue._();

  static const Color _amber = Color(0xFFE2A356);
  static const Color _grey = Color(0xFF8D93A1);
  static const Color _charcoal = Color(0xFF4A4F58);
  static const Color _cream = Color(0xFFF0E2CC);
  static const Color _ginger = Color(0xFFD9793F);
  static const Color _white = Color(0xFFF7F5F2);
  static const Color _brown = Color(0xFF9C7350);
  static const Color _slate = Color(0xFF6F7F94);

  static const Color _green = Color(0xFF6FA57C);
  static const Color _gold = Color(0xFFD8A93A);
  static const Color _blue = Color(0xFF6E8FC0);

  static const List<CatReward> all = <CatReward>[
    // Waiting for him the first time he opens it — nobody starts with nothing.
    CatReward(
      cat: Cat(
        id: 'smudge',
        name: 'Smudge',
        coat: _grey,
        marking: _charcoal,
        pattern: CatPattern.tabby,
        eyes: _green,
      ),
      source: CatSource.start,
      threshold: 0,
    ),

    // Turning up. These arrive whatever the reading is doing.
    CatReward(
      cat: Cat(
        id: 'biscuit',
        name: 'Biscuit',
        coat: _cream,
        marking: _brown,
        pattern: CatPattern.mitts,
        eyes: _gold,
      ),
      source: CatSource.streak,
      threshold: 2,
    ),
    CatReward(
      cat: Cat(
        id: 'domino',
        name: 'Domino',
        coat: _charcoal,
        marking: _white,
        pattern: CatPattern.tuxedo,
        eyes: _green,
      ),
      source: CatSource.streak,
      threshold: 4,
    ),
    CatReward(
      cat: Cat(
        id: 'marmalade',
        name: 'Marmalade',
        coat: _ginger,
        marking: Color(0xFFB4592A),
        pattern: CatPattern.tabby,
        eyes: _gold,
      ),
      source: CatSource.streak,
      threshold: 7,
    ),
    CatReward(
      cat: Cat(
        id: 'snowy',
        name: 'Snowy',
        coat: _white,
        marking: Color(0xFFDCD6CE),
        pattern: CatPattern.plain,
        eyes: _blue,
      ),
      source: CatSource.streak,
      threshold: 14,
    ),
    CatReward(
      cat: Cat(
        id: 'shadow',
        name: 'Shadow',
        coat: Color(0xFF3A3F49),
        marking: Color(0xFF2B2F36),
        pattern: CatPattern.plain,
        eyes: _gold,
      ),
      source: CatSource.streak,
      threshold: 30,
    ),

    // Reading further up and down the staff.
    CatReward(
      cat: Cat(
        id: 'socks',
        name: 'Socks',
        coat: _slate,
        marking: _white,
        pattern: CatPattern.mitts,
        eyes: _green,
      ),
      source: CatSource.level,
      threshold: 2,
    ),
    CatReward(
      cat: Cat(
        id: 'pepper',
        name: 'Pepper',
        coat: _charcoal,
        marking: _grey,
        pattern: CatPattern.tabby,
        eyes: _gold,
      ),
      source: CatSource.level,
      threshold: 3,
    ),
    CatReward(
      cat: Cat(
        id: 'clover',
        name: 'Clover',
        coat: _amber,
        marking: _cream,
        pattern: CatPattern.patch,
        eyes: _green,
      ),
      source: CatSource.level,
      threshold: 4,
    ),
    CatReward(
      cat: Cat(
        id: 'mittens',
        name: 'Mittens',
        coat: _brown,
        marking: _white,
        pattern: CatPattern.mitts,
        eyes: _blue,
      ),
      source: CatSource.level,
      threshold: 5,
    ),
    CatReward(
      cat: Cat(
        id: 'pumpkin',
        name: 'Pumpkin',
        coat: Color(0xFFE08A3C),
        marking: _white,
        pattern: CatPattern.patch,
        eyes: _green,
      ),
      source: CatSource.level,
      threshold: 6,
    ),
    CatReward(
      cat: Cat(
        id: 'tiger',
        name: 'Tiger',
        coat: _amber,
        marking: Color(0xFF7A5327),
        pattern: CatPattern.tabby,
        eyes: _gold,
      ),
      source: CatSource.level,
      threshold: 7,
    ),
    CatReward(
      cat: Cat(
        id: 'jem',
        name: 'Jem',
        coat: _white,
        marking: _ginger,
        pattern: CatPattern.patch,
        eyes: _blue,
      ),
      source: CatSource.level,
      threshold: 8,
    ),
  ];

  /// The cats earned by reaching [level] and by a longest streak of [streak].
  ///
  /// Takes the **longest streak ever**, not the current one, because a cat is
  /// never taken away. Breaking a streak loses the number, not a friend.
  static List<CatReward> earned({
    required int highestLevel,
    required int longestStreak,
  }) {
    return all.where((CatReward r) {
      return switch (r.source) {
        CatSource.start => true,
        CatSource.level => highestLevel >= r.threshold,
        CatSource.streak => longestStreak >= r.threshold,
      };
    }).toList();
  }

  /// The next cat he could meet, or null once he has them all.
  ///
  /// Picks the one **closest to reach**, not the next in catalogue order.
  /// Ordering by the list would offer "practise 14 days in a row" while a cat
  /// one level away sat unmentioned — pointing a six-year-old at the most
  /// distant of his options is worse than saying nothing.
  ///
  /// Levels and days are not really the same unit, but the distance to each is
  /// close enough to compare, and the alternative is picking arbitrarily.
  static CatReward? next({
    required int highestLevel,
    required int longestStreak,
  }) {
    final Set<String> have = earned(
      highestLevel: highestLevel,
      longestStreak: longestStreak,
    ).map((CatReward r) => r.cat.id).toSet();

    CatReward? best;
    int bestDistance = 1 << 30;
    for (final CatReward reward in all) {
      if (have.contains(reward.cat.id)) continue;
      final int distance = switch (reward.source) {
        CatSource.start => 0,
        CatSource.level => reward.threshold - highestLevel,
        CatSource.streak => reward.threshold - longestStreak,
      };
      if (distance < bestDistance) {
        bestDistance = distance;
        best = reward;
      }
    }
    return best;
  }
}
