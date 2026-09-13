import 'package:flutter/foundation.dart';

import '../music/clef.dart';
import '../music/pitch.dart';

/// Vertical layout of a grand staff, in logical pixels, derived from one unit:
/// the staff space.
///
/// Bravura — like every SMuFL font — is designed so that one em equals four
/// staff spaces, so a glyph font size of `4 * staffSpace` makes clefs and
/// noteheads come out at engraving-correct proportions for free. That is the
/// only reason this class exists rather than hard-coded pixel values.
///
/// Coordinates increase downward, as they do on a canvas. y = 0 is the treble
/// staff's top line.
///
/// ## Why the staves are four spaces apart
///
/// The gap decides whether the two clefs' pitch mappings stay in the right
/// order. With a four-space gap, middle C written as a ledger line below the
/// treble staff lands *above* B3 written in the space above the bass staff —
/// which is what a reader expects. Narrow the gap and those two cross over,
/// making the grand staff lie about which note is higher.
@immutable
class StaffGeometry {
  const StaffGeometry({required this.staffSpace, this.interStaffGapSpaces = 4});

  /// Distance between two adjacent staff lines. The unit of everything here.
  final double staffSpace;

  /// Vertical distance between the treble staff's bottom line and the bass
  /// staff's top line, in staff spaces. See the class doc for why 4.
  final double interStaffGapSpaces;

  /// Font size that makes Bravura glyphs match this staff's proportions.
  double get glyphFontSize => 4 * staffSpace;

  double get trebleTopY => 0;
  double get trebleBottomY => 4 * staffSpace;
  double get bassTopY => trebleBottomY + interStaffGapSpaces * staffSpace;
  double get bassBottomY => bassTopY + 4 * staffSpace;

  /// Height of both staves plus the gap, excluding any margin for ledger lines.
  double get height => bassBottomY;

  double topYOf(Clef clef) => clef == Clef.treble ? trebleTopY : bassTopY;
  double bottomYOf(Clef clef) =>
      clef == Clef.treble ? trebleBottomY : bassBottomY;

  /// The five line positions of one staff, top to bottom.
  List<double> lineYsOf(Clef clef) {
    final double top = topYOf(clef);
    return <double>[for (int i = 0; i < 5; i++) top + i * staffSpace];
  }

  /// Vertical centre of [pitch]'s notehead when written in [clef].
  ///
  /// One diatonic step is half a staff space: consecutive letters alternate
  /// between sitting on a line and sitting in the space above it.
  double yForPitch(Pitch pitch, Clef clef) {
    final int stepsAboveBottomLine =
        pitch.diatonicStep - clef.bottomLinePitch.diatonicStep;
    return bottomYOf(clef) - stepsAboveBottomLine * 0.5 * staffSpace;
  }

  /// Ledger lines needed to reach [pitch] in [clef], nearest the staff first.
  ///
  /// Empty when the note sits on or within the staff, and — importantly — also
  /// empty for a note in the space just outside it (B3 in bass, D4 in treble),
  /// which needs no ledger line because it is not on a line position.
  List<double> ledgerLineYsFor(Pitch pitch, Clef clef) {
    const double epsilon = 1e-9;
    final double y = yForPitch(pitch, clef);
    final double top = topYOf(clef);
    final double bottom = bottomYOf(clef);
    final List<double> ys = <double>[];

    if (y > bottom + epsilon) {
      for (
        double ly = bottom + staffSpace;
        ly <= y + epsilon;
        ly += staffSpace
      ) {
        ys.add(ly);
      }
    } else if (y < top - epsilon) {
      for (double ly = top - staffSpace; ly >= y - epsilon; ly -= staffSpace) {
        ys.add(ly);
      }
    }
    return ys;
  }

  /// The clef a reader would expect for [pitch] on a piano grand staff: middle
  /// C and above in the treble, below it in the bass.
  ///
  /// Middle C itself is writable in either clef, at two different heights, so
  /// callers that care (the exercise, which varies it deliberately) pass a clef
  /// explicitly rather than relying on this.
  static Clef defaultClefFor(Pitch pitch) =>
      pitch.diatonicStep >= Pitch.middleC.diatonicStep
      ? Clef.treble
      : Clef.bass;
}
