import 'package:flutter/foundation.dart';

/// The seven diatonic letter names, ascending from C.
///
/// Staff position is a function of *diatonic* step, not semitones — B to C is
/// one staff step exactly as C to D is, despite being a semitone rather than a
/// tone. Everything in this file therefore counts letters, never semitones.
enum NoteLetter {
  c('C', 0),
  d('D', 1),
  e('E', 2),
  f('F', 3),
  g('G', 4),
  a('A', 5),
  b('B', 6);

  const NoteLetter(this.label, this.stepsFromC);

  /// Single upper-case letter as a child would say it.
  final String label;

  /// Distance above C within one octave, in staff steps.
  final int stepsFromC;

  static NoteLetter fromLabel(String label) {
    final String wanted = label.toUpperCase();
    for (final NoteLetter letter in values) {
      if (letter.label == wanted) return letter;
    }
    throw ArgumentError.value(label, 'label', 'not a note letter A-G');
  }
}

/// A natural pitch in scientific pitch notation, e.g. `C4` for middle C.
///
/// Naturals only: sharps and flats are deferred to level 9+ of the ladder in
/// RFC-0001, and adding them must not disturb [diatonicStep], because an
/// accidental changes a note's *sound* without changing its staff position.
@immutable
class Pitch implements Comparable<Pitch> {
  const Pitch(this.letter, this.octave);

  final NoteLetter letter;
  final int octave;

  /// Middle C — the note the whole app is centred on.
  static const Pitch middleC = Pitch(NoteLetter.c, 4);

  /// Count of diatonic steps above C0.
  ///
  /// Adjacent letters differ by exactly 1, which makes this the natural unit of
  /// vertical position: one step is half a staff space, whatever the clef.
  int get diatonicStep => octave * 7 + letter.stepsFromC;

  /// Parses scientific pitch notation such as `C4`, `b3`, `A-1`.
  static Pitch parse(String text) {
    final RegExpMatch? match = RegExp(r'^([A-Ga-g])(-?\d+)$')
        .firstMatch(text.trim());
    if (match == null) {
      throw ArgumentError.value(
        text,
        'text',
        'expected scientific pitch notation like C4',
      );
    }
    return Pitch(
      NoteLetter.fromLabel(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  /// Every natural pitch from [from] to [to] inclusive, ascending.
  static List<Pitch> range(Pitch from, Pitch to) {
    final List<Pitch> result = <Pitch>[];
    for (int step = from.diatonicStep; step <= to.diatonicStep; step++) {
      result.add(Pitch(NoteLetter.values[step % 7], step ~/ 7));
    }
    return result;
  }

  String get scientificName => '${letter.label}$octave';

  @override
  int compareTo(Pitch other) => diatonicStep.compareTo(other.diatonicStep);

  @override
  bool operator ==(Object other) =>
      other is Pitch && other.letter == letter && other.octave == octave;

  @override
  int get hashCode => Object.hash(letter, octave);

  @override
  String toString() => scientificName;
}
