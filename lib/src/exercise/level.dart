import 'package:flutter/foundation.dart';

import '../music/pitch.dart';

/// A rung of the ladder in RFC-0001: the set of notes a round may ask.
///
/// Levels are data, not code. Widening the ladder is adding entries here, which
/// is the whole reason the keyboard's extent and the staff's geometry were
/// fixed up front.
@immutable
class Level {
  const Level({required this.number, required this.pitches});

  final int number;
  final List<Pitch> pitches;

  /// Level 1: middle C and its two neighbours.
  ///
  /// These three sit in the gap between the staves, which is why the renderer
  /// needed ledger lines on day one — and why they were the notes finger
  /// numbers were easiest to fall back on.
  static final Level one = Level(
    number: 1,
    pitches: <Pitch>[Pitch.parse('B3'), Pitch.middleC, Pitch.parse('D4')],
  );

  Set<Pitch> get pitchSet => pitches.toSet();
}
