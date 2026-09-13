import 'dart:math';

import '../music/pitch.dart';

/// Chooses which note to ask next, favouring the ones he keeps getting wrong.
///
/// RFC-0001 D7. Five minutes between lessons is a small budget, so it should be
/// spent where the difficulty actually is rather than spread evenly.
///
/// Two rules shape it:
///
/// * **A miss raises a note's weight, a correct answer lowers it again.** The
///   bonus is capped so a single bad patch cannot make one note crowd out the
///   rest for the remainder of the round.
/// * **Never the same note twice running.** Without this, heavy weighting
///   produces the same note three or four times in a row, which reads as a
///   broken app rather than as practice — and he stops reading the staff and
///   just repeats his last answer.
class PitchSelector {
  PitchSelector({required List<Pitch> pitches, Random? random})
    : _pitches = List<Pitch>.unmodifiable(pitches),
      _random = random ?? Random() {
    if (_pitches.isEmpty) {
      throw ArgumentError.value(pitches, 'pitches', 'must not be empty');
    }
  }

  final List<Pitch> _pitches;
  final Random _random;
  final Map<Pitch, int> _missCount = <Pitch, int>{};

  Pitch? _lastAsked;

  /// Extra weight per outstanding miss, and the cap on it.
  static const int _missBonus = 1;
  static const int _maxMissBonus = 3;

  void recordMiss(Pitch pitch) {
    final int current = _missCount[pitch] ?? 0;
    _missCount[pitch] = (current + 1).clamp(0, _maxMissBonus);
  }

  void recordCorrect(Pitch pitch) {
    final int current = _missCount[pitch] ?? 0;
    if (current > 0) _missCount[pitch] = current - 1;
  }

  int weightOf(Pitch pitch) => 1 + _missBonus * (_missCount[pitch] ?? 0);

  /// The next note to ask.
  ///
  /// [require] forces the choice among specific notes — used to guarantee a
  /// missed note comes back before the round ends.
  Pitch next({Set<Pitch>? require}) {
    List<Pitch> candidates = require == null
        ? _pitches
        : _pitches.where(require.contains).toList();
    if (candidates.isEmpty) candidates = _pitches;

    // Drop the immediately preceding note, unless it is the only option.
    final List<Pitch> withoutRepeat = candidates
        .where((Pitch p) => p != _lastAsked)
        .toList();
    if (withoutRepeat.isNotEmpty) candidates = withoutRepeat;

    final int total = candidates.fold(
      0,
      (int sum, Pitch p) => sum + weightOf(p),
    );
    int roll = _random.nextInt(total);
    for (final Pitch pitch in candidates) {
      roll -= weightOf(pitch);
      if (roll < 0) {
        _lastAsked = pitch;
        return pitch;
      }
    }
    _lastAsked = candidates.last;
    return candidates.last;
  }
}
