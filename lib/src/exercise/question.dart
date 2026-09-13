import 'dart:math';

import 'package:flutter/foundation.dart';

import '../music/clef.dart';
import '../music/pitch.dart';
import '../staff/staff_geometry.dart';

/// One thing to ask: a pitch, and the clef it is written in.
@immutable
class Question {
  const Question({required this.pitch, required this.clef});

  final Pitch pitch;
  final Clef clef;

  /// Chooses how to write [pitch].
  ///
  /// Middle C is legal in either clef, at two visibly different heights, and he
  /// has to read both — so it is picked at random per question rather than
  /// pinned to one (RFC-0001 OQ-3). Every other pitch has only one sensible
  /// clef on a grand staff.
  factory Question.forPitch(Pitch pitch, Random random) {
    if (pitch == Pitch.middleC) {
      return Question(
        pitch: pitch,
        clef: random.nextBool() ? Clef.treble : Clef.bass,
      );
    }
    return Question(pitch: pitch, clef: StaffGeometry.defaultClefFor(pitch));
  }

  @override
  bool operator ==(Object other) =>
      other is Question && other.pitch == pitch && other.clef == clef;

  @override
  int get hashCode => Object.hash(pitch, clef);

  @override
  String toString() => '${pitch.scientificName} in ${clef.name}';
}
