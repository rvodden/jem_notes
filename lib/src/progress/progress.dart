import 'package:flutter/foundation.dart';

import '../exercise/level.dart';

/// Accuracy at or above which a round counts toward unlocking the next level,
/// and earns at least two stars.
const double kHighAccuracy = 0.9;

/// Rounds at high accuracy, on this many *distinct days*, to unlock the next
/// level.
///
/// RFC-0001 D6: consistency across sessions, not one good round. A six-year-old
/// can fluke a short round, and unlocking too early is how he ends up stuck on
/// material he cannot read.
const int kUnlockDistinctDays = 2;

/// One finished round.
@immutable
class RoundRecord {
  const RoundRecord({
    required this.level,
    required this.day,
    required this.asked,
    required this.firstTimeCorrect,
  });

  final int level;

  /// The calendar day it was completed, with no time component — the streak
  /// counts days, not moments.
  final DateTime day;

  final int asked;
  final int firstTimeCorrect;

  double get accuracy => asked == 0 ? 0 : firstTimeCorrect / asked;

  /// Stars for this round, by accuracy alone.
  ///
  /// Never by speed: accuracy comes first, and there is no clock (RFC-0001).
  int get stars {
    if (asked == 0) return 0;
    if (firstTimeCorrect == asked) return 3;
    if (accuracy >= kHighAccuracy) return 2;
    return 1;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'level': level,
    'day': _dayToString(day),
    'asked': asked,
    'firstTimeCorrect': firstTimeCorrect,
  };

  static RoundRecord fromJson(Map<String, Object?> json) => RoundRecord(
    level: json['level']! as int,
    day: _dayFromString(json['day']! as String),
    asked: json['asked']! as int,
    firstTimeCorrect: json['firstTimeCorrect']! as int,
  );

  @override
  bool operator ==(Object other) =>
      other is RoundRecord &&
      other.level == level &&
      other.day == day &&
      other.asked == asked &&
      other.firstTimeCorrect == firstTimeCorrect;

  @override
  int get hashCode => Object.hash(level, day, asked, firstTimeCorrect);
}

/// How one note has gone, across every round ever played.
@immutable
class PitchStat {
  const PitchStat({this.asked = 0, this.missed = 0});

  final int asked;
  final int missed;

  PitchStat plus({required bool missed}) =>
      PitchStat(asked: asked + 1, missed: this.missed + (missed ? 1 : 0));

  Map<String, Object?> toJson() => <String, Object?>{
    'asked': asked,
    'missed': missed,
  };

  static PitchStat fromJson(Map<String, Object?> json) =>
      PitchStat(asked: json['asked']! as int, missed: json['missed']! as int);

  @override
  bool operator ==(Object other) =>
      other is PitchStat && other.asked == asked && other.missed == missed;

  @override
  int get hashCode => Object.hash(asked, missed);
}

/// Everything the app remembers between sessions.
///
/// One learner, on one device, with no account — RFC-0001 D10. There is nothing
/// here that identifies a child, and nothing that leaves the tablet.
@immutable
class Progress {
  const Progress({
    this.rounds = const <RoundRecord>[],
    this.pitchStats = const <String, PitchStat>{},
  });

  final List<RoundRecord> rounds;

  /// Keyed by scientific pitch name, e.g. `C4`.
  final Map<String, PitchStat> pitchStats;

  /// Distinct days on which at least one round was completed, most recent last.
  List<DateTime> get practiceDays {
    final Set<DateTime> days = rounds.map((RoundRecord r) => r.day).toSet();
    return days.toList()..sort();
  }

  /// Consecutive days practised, counting back from the most recent.
  ///
  /// RFC-0001 D8: the streak counts **turning up**, not being right. A streak
  /// of correct answers would punish exactly the stretch where he is slower
  /// with letter names than with finger numbers — the stretch where a child
  /// gives up on a new strategy.
  int get streak {
    final List<DateTime> days = practiceDays;
    if (days.isEmpty) return 0;
    int streak = 1;
    for (int i = days.length - 1; i > 0; i--) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// The longest run of consecutive practice days ever achieved.
  ///
  /// Cats are earned against this rather than the current streak, because a cat
  /// is never taken away (DEC-0007). Breaking a streak loses the number, not a
  /// friend.
  int get longestStreak {
    final List<DateTime> days = practiceDays;
    if (days.isEmpty) return 0;
    int best = 1;
    int run = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  /// Highest level reached. Level 1 is always available.
  int get highestUnlockedLevel {
    int unlocked = 1;
    while (_unlocksNext(unlocked)) {
      unlocked++;
    }
    return unlocked;
  }

  bool isUnlocked(int level) => level <= highestUnlockedLevel;

  /// Whether enough consistent work has been done at [level] to open the next.
  bool _unlocksNext(int level) {
    final Set<DateTime> qualifyingDays = rounds
        .where(
          (RoundRecord r) => r.level == level && r.accuracy >= kHighAccuracy,
        )
        .map((RoundRecord r) => r.day)
        .toSet();
    // Never unlock past the end of the ladder.
    return level < Level.highestNumber &&
        qualifyingDays.length >= kUnlockDistinctDays;
  }

  Progress withRound(RoundRecord record, Map<String, PitchStat> stats) =>
      Progress(
        rounds: <RoundRecord>[...rounds, record],
        pitchStats: <String, PitchStat>{...pitchStats, ...stats},
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'version': 1,
    'rounds': rounds.map((RoundRecord r) => r.toJson()).toList(),
    'pitchStats': pitchStats.map(
      (String k, PitchStat v) => MapEntry<String, Object?>(k, v.toJson()),
    ),
  };

  static Progress fromJson(Map<String, Object?> json) {
    final List<Object?> rounds =
        (json['rounds'] as List<Object?>?) ?? const <Object?>[];
    final Map<String, Object?> stats =
        (json['pitchStats'] as Map<String, Object?>?) ??
        const <String, Object?>{};
    return Progress(
      rounds: rounds
          .map((Object? r) => RoundRecord.fromJson(r! as Map<String, Object?>))
          .toList(),
      pitchStats: stats.map(
        (String k, Object? v) => MapEntry<String, PitchStat>(
          k,
          PitchStat.fromJson(v! as Map<String, Object?>),
        ),
      ),
    );
  }
}

/// Strips the time off a timestamp, so "today" means the calendar day.
DateTime dayOf(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

String _dayToString(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

DateTime _dayFromString(String text) {
  final List<String> parts = text.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
