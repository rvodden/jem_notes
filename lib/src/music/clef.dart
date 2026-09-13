import 'pitch.dart';

/// The two clefs of a piano grand staff.
///
/// Each clef is defined by the pitch on its bottom line, plus the pitch its
/// glyph anchors to — a clef glyph is drawn with its baseline sitting on the
/// line of the note it names (G for treble, F for bass), which is what makes
/// clefs meaningful rather than decorative.
enum Clef {
  treble(
    bottomLinePitch: Pitch(NoteLetter.e, 4),
    anchorPitch: Pitch(NoteLetter.g, 4),
    glyph: '', // SMuFL gClef
  ),
  bass(
    bottomLinePitch: Pitch(NoteLetter.g, 2),
    anchorPitch: Pitch(NoteLetter.f, 3),
    glyph: '', // SMuFL fClef
  );

  const Clef({
    required this.bottomLinePitch,
    required this.anchorPitch,
    required this.glyph,
  });

  final Pitch bottomLinePitch;
  final Pitch anchorPitch;

  /// The SMuFL codepoint for this clef, as a Bravura-renderable string.
  final String glyph;

  /// The pitch on this clef's top line, four staff spaces up from the bottom.
  Pitch get topLinePitch {
    final int step = bottomLinePitch.diatonicStep + 8;
    return Pitch(NoteLetter.values[step % 7], step ~/ 7);
  }
}
