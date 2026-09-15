import 'package:flutter/foundation.dart';

import '../cats/cat.dart';
import '../exercise/exercise_round.dart';
import '../exercise/level.dart';
import '../music/pitch.dart';
import 'progress.dart';
import 'progress_store.dart';

/// Loads progress, records finished rounds, and decides what is unlocked.
///
/// Holds the only mutable state the app keeps between sessions.
class ProgressController extends ChangeNotifier {
  ProgressController({
    required this.store,
    // Injectable so streak and unlock rules can be tested across days without
    // waiting for one.
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ProgressStore store;
  final DateTime Function() _now;

  Progress _progress = const Progress();
  bool _loaded = false;

  Progress get progress => _progress;
  bool get isLoaded => _loaded;

  int get streak => _progress.streak;
  int get highestUnlockedLevel => _progress.highestUnlockedLevel;

  /// Levels the child may choose. Never includes a locked one.
  List<Level> get unlockedLevels => Level.ladder
      .where((Level level) => _progress.isUnlocked(level.number))
      .toList();

  /// Every cat he has met.
  List<CatReward> get cats => CatCatalogue.earned(
    highestLevel: _progress.highestUnlockedLevel,
    longestStreak: _progress.longestStreak,
  );

  /// The next cat to look forward to, or null once he has them all.
  CatReward? get nextCat => CatCatalogue.next(
    highestLevel: _progress.highestUnlockedLevel,
    longestStreak: _progress.longestStreak,
  );

  /// The cats that arrived because of the round just recorded.
  List<CatReward> newCats = <CatReward>[];

  Future<void> load() async {
    _progress = await store.load();
    _loaded = true;
    notifyListeners();
  }

  /// Miss counts to seed a round's weighting, so a note he struggled with in an
  /// earlier session still comes round more often now.
  Map<Pitch, int> missCountsFor(Level level) {
    final Map<Pitch, int> counts = <Pitch, int>{};
    for (final Pitch pitch in level.pitches) {
      final PitchStat? stat = _progress.pitchStats[pitch.scientificName];
      if (stat != null && stat.missed > 0) counts[pitch] = stat.missed;
    }
    return counts;
  }

  /// Records a finished round and persists it. Returns the record, whose
  /// [RoundRecord.stars] the summary screen shows.
  Future<RoundRecord> recordRound(ExerciseRound round) async {
    final RoundSummary summary = round.summary;
    final RoundRecord record = RoundRecord(
      level: round.level.number,
      day: dayOf(_now()),
      asked: summary.asked,
      firstTimeCorrect: summary.firstTimeCorrect,
    );

    final Map<String, PitchStat> stats = <String, PitchStat>{
      ..._progress.pitchStats,
    };
    round.askedPerPitch.forEach((Pitch pitch, int asked) {
      final String key = pitch.scientificName;
      final int missed = round.missedPerPitch[pitch] ?? 0;
      final PitchStat existing = stats[key] ?? const PitchStat();
      stats[key] = PitchStat(
        asked: existing.asked + asked,
        missed: existing.missed + missed,
      );
    });

    final Set<String> before = cats.map((CatReward r) => r.cat.id).toSet();
    _progress = _progress.withRound(record, stats);
    newCats = cats.where((CatReward r) => !before.contains(r.cat.id)).toList();
    notifyListeners();
    await store.save(_progress);
    return record;
  }
}
