import 'package:flutter/foundation.dart';

import '../music/pitch.dart';

/// One physical key of the on-screen piano.
///
/// A white key *is* a natural pitch. A black key is modelled by the white key
/// immediately below it rather than by a pitch of its own, because naming it
/// would force a decision this project has not had to make yet: the same black
/// key is both a sharp and a flat, and RFC-0001 defers accidentals to level 9+.
/// Modelling the physical key now and naming it later keeps [Pitch] honest —
/// it stays a naturals-only type — and leaves the enharmonic choice to the
/// level that actually asks a child to read one.
@immutable
class PianoKey {
  /// A white key, which is exactly the natural [pitch].
  const PianoKey.white(this.naturalBelow) : isBlack = false;

  /// The black key immediately above white key [naturalBelow].
  const PianoKey.black(this.naturalBelow) : isBlack = true;

  /// For a white key, the key's own pitch. For a black key, the white key to
  /// its left.
  final Pitch naturalBelow;

  final bool isBlack;

  /// The pitch this key sounds, or null for a black key — which has no name
  /// until accidentals arrive.
  Pitch? get pitch => isBlack ? null : naturalBelow;

  /// The letters that have a black key immediately above them. There is none
  /// between E and F, nor between B and C — the two places where adjacent
  /// white keys are already a semitone apart.
  static const Set<NoteLetter> lettersWithBlackAbove = <NoteLetter>{
    NoteLetter.c,
    NoteLetter.d,
    NoteLetter.f,
    NoteLetter.g,
    NoteLetter.a,
  };

  bool get hasBlackAbove => lettersWithBlackAbove.contains(naturalBelow.letter);

  @override
  bool operator ==(Object other) =>
      other is PianoKey &&
      other.naturalBelow == naturalBelow &&
      other.isBlack == isBlack;

  @override
  int get hashCode => Object.hash(naturalBelow, isBlack);

  @override
  String toString() => isBlack
      ? 'black above ${naturalBelow.scientificName}'
      : naturalBelow.scientificName;
}
