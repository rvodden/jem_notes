import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../music/clef.dart';
import '../music/pitch.dart';
import 'staff_geometry.dart';

/// SMuFL codepoints used here. Bravura maps these at the standard positions.
class _Glyph {
  static const String noteheadBlack = '';
  static const String brace = '';
}

/// Font family name as declared in pubspec.yaml.
const String kBravura = 'Bravura';

/// Draws a braced grand staff with exactly one note on it.
///
/// Deliberately stateless and answer-agnostic: this widget knows about pitches
/// and clefs and nothing about questions, scoring or input. RFC-0001 phase 1.
///
/// It renders **no finger numbers**, ever. Those are the competing strategy the
/// whole app exists to displace (RFC-0001), so there is no code path here that
/// could draw one.
class StaffView extends StatelessWidget {
  const StaffView({
    required this.pitch,
    required this.clef,
    this.color,
    super.key,
  });

  /// The single note to draw.
  final Pitch pitch;

  /// Which clef to write [pitch] in. Middle C is legal in both, at different
  /// heights, so the caller chooses.
  final Clef clef;

  /// Ink colour; defaults to the theme's onSurface so it works in both themes.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrandStaffPainter(
        pitch: pitch,
        clef: clef,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
      // Fills whatever it is given; the painter scales to fit.
      child: const SizedBox.expand(),
    );
  }
}

class _GrandStaffPainter extends CustomPainter {
  _GrandStaffPainter({
    required this.pitch,
    required this.clef,
    required this.color,
  });

  final Pitch pitch;
  final Clef clef;
  final Color color;

  /// Vertical margin above and below the staves, in staff spaces, so that
  /// ledger lines and high or low notes never clip.
  static const double _marginSpaces = 2;

  /// Staves plus gap occupy 12 spaces; margin adds 2 top and bottom.
  static const double _totalSpacesTall = 12 + 2 * _marginSpaces;

  /// Narrowest the furniture (brace, barline, clefs, one note) can be squeezed
  /// before it starts to overlap, in staff spaces.
  static const double _minSpacesWide = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Scale to fit both dimensions, so the staff never clips whatever aspect
    // ratio it is handed.
    final double staffSpace = math.min(
      size.height / _totalSpacesTall,
      // Width only constrains when the box is so narrow the clefs would not
      // fit; otherwise the staff stretches across whatever width it is given,
      // as a line of sheet music does.
      size.width / _minSpacesWide,
    );
    final StaffGeometry geometry = StaffGeometry(staffSpace: staffSpace);

    canvas.save();
    // Centre the whole grand staff in the available box.
    canvas.translate(0, (size.height - geometry.height) / 2);

    final Paint ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      // Engraving convention: staff lines are ~0.13 staff spaces thick.
      ..strokeWidth = staffSpace * 0.13;

    final double staffLeft = staffSpace * 1.8;
    final double staffRight = size.width;

    _drawStaffLines(canvas, geometry, ink, staffLeft, staffRight);
    _drawLeftBarline(canvas, geometry, ink, staffLeft);
    _drawBrace(canvas, geometry, staffLeft);

    final double clefLeft = staffLeft + staffSpace * 0.4;
    final double afterClef = _drawClefs(canvas, geometry, clefLeft);

    // Place the note in the middle of the space left after the clefs.
    final double noteX = afterClef + (staffRight - afterClef) * 0.45;
    _drawLedgerLines(canvas, geometry, ink, noteX);
    _drawNotehead(canvas, geometry, noteX);

    canvas.restore();
  }

  void _drawStaffLines(
    Canvas canvas,
    StaffGeometry geometry,
    Paint ink,
    double left,
    double right,
  ) {
    for (final Clef staff in Clef.values) {
      for (final double y in geometry.lineYsOf(staff)) {
        canvas.drawLine(Offset(left, y), Offset(right, y), ink);
      }
    }
  }

  void _drawLeftBarline(
    Canvas canvas,
    StaffGeometry geometry,
    Paint ink,
    double x,
  ) {
    canvas.drawLine(
      Offset(x, geometry.trebleTopY),
      Offset(x, geometry.bassBottomY),
      ink,
    );
  }

  /// The brace spans both staves, which is what makes the pair read as one
  /// instrument rather than two unrelated staves.
  ///
  /// Bravura's `brace` was measured by rasterising it and scanning the ink box:
  /// its height is 0.9975 em and it sits **entirely above** the baseline
  /// (aboveBaseline/fontSize = 1.0, belowBaseline ≈ 0). So a font size equal to
  /// the span wanted gives the right height, and the baseline goes at the
  /// *bottom* of that span — not its middle, which clips the top half off and
  /// leaves the brace ending halfway down.
  ///
  /// Sizing via font size rather than a one-axis canvas scale also keeps the
  /// stroke weights proportional; stretching it vertically turns it into a
  /// squiggle.
  void _drawBrace(Canvas canvas, StaffGeometry geometry, double barlineX) {
    final TextPainter painter = _glyphPainter(_Glyph.brace, geometry.height);
    if (painter.width <= 0) return;
    _paintOnBaseline(
      canvas,
      painter,
      barlineX - painter.width - geometry.staffSpace * 0.2,
      geometry.bassBottomY,
    );
  }

  /// Draws both clef glyphs, each anchored on the line of the note it names,
  /// and returns the x just past the wider of the two.
  double _drawClefs(Canvas canvas, StaffGeometry geometry, double left) {
    double widest = 0;
    for (final Clef staff in Clef.values) {
      final TextPainter painter = _glyphPainter(
        staff.glyph,
        geometry.glyphFontSize,
      );
      final double anchorY = geometry.yForPitch(staff.anchorPitch, staff);
      _paintOnBaseline(canvas, painter, left, anchorY);
      widest = math.max(widest, painter.width);
    }
    return left + widest;
  }

  void _drawLedgerLines(
    Canvas canvas,
    StaffGeometry geometry,
    Paint ink,
    double noteX,
  ) {
    // Ledger lines extend a little past the notehead on both sides.
    final double half = geometry.staffSpace * 0.95;
    for (final double y in geometry.ledgerLineYsFor(pitch, clef)) {
      canvas.drawLine(Offset(noteX - half, y), Offset(noteX + half, y), ink);
    }
  }

  void _drawNotehead(Canvas canvas, StaffGeometry geometry, double x) {
    final TextPainter painter = _glyphPainter(
      _Glyph.noteheadBlack,
      geometry.glyphFontSize,
    );
    // A notehead glyph's baseline runs through its vertical centre, so the
    // pitch's y IS the baseline — no half-height fudging.
    _paintOnBaseline(
      canvas,
      painter,
      x - painter.width / 2,
      geometry.yForPitch(pitch, clef),
    );
  }

  TextPainter _glyphPainter(String glyph, double fontSize) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontFamily: kBravura,
          fontSize: fontSize,
          color: color,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter;
  }

  /// Paints [painter] so its alphabetic baseline lands exactly on [baselineY].
  ///
  /// SMuFL positions every glyph relative to that baseline, so this is the one
  /// operation that turns "which note" into "where on the staff".
  void _paintOnBaseline(
    Canvas canvas,
    TextPainter painter,
    double x,
    double baselineY,
  ) {
    final double toBaseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.paint(canvas, Offset(x, baselineY - toBaseline));
  }

  @override
  bool shouldRepaint(_GrandStaffPainter oldDelegate) =>
      oldDelegate.pitch != pitch ||
      oldDelegate.clef != clef ||
      oldDelegate.color != color;
}
