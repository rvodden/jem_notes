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
  static Level get one => ladder.first;

  Set<Pitch> get pitchSet => pitches.toSet();

  /// The ladder from RFC-0001, widening outward from middle C and ending at
  /// the full white-note range of Poco Piano Book 2.
  ///
  /// Levels are data: adding a rung is an entry here, not new code. Sharps and
  /// flats are level 9+ and deliberately absent — Book 2 introduces them, but
  /// naming a black key is a decision this project has not had to make yet.
  static final List<Level> ladder = <Level>[
    // Middle C and its neighbours.
    Level(number: 1, pitches: _range('B3', 'D4')),
    // Spans the gap between the staves.
    Level(number: 2, pitches: _range('A3', 'E4')),
    // Right-hand C position, in the treble staff proper.
    Level(number: 3, pitches: _range('C4', 'G4')),
    // Left-hand C position, in the bass staff proper.
    Level(number: 4, pitches: _range('F3', 'C4')),
    // Both hands together.
    Level(number: 5, pitches: _range('F3', 'G4')),
    // Full treble octave, reaching Treble C.
    Level(number: 6, pitches: _range('C4', 'C5')),
    // Full bass octave, reaching Bass C.
    Level(number: 7, pitches: _range('C3', 'C4')),
    // Book 2's complete white-note range.
    Level(number: 8, pitches: _range('C3', 'C5')),
  ];

  static List<Pitch> _range(String from, String to) =>
      Pitch.range(Pitch.parse(from), Pitch.parse(to));

  /// The level with this number, or null if the ladder does not go that high.
  static Level? byNumber(int number) {
    for (final Level level in ladder) {
      if (level.number == number) return level;
    }
    return null;
  }

  static int get highestNumber => ladder.last.number;
}
