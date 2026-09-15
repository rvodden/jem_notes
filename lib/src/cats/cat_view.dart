import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cat.dart';

/// Draws a cat.
///
/// Vector, like the staff and the keyboard: no image assets, no licensing, and
/// it stays sharp at any size on any screen. Simple and friendly is the brief —
/// this is a six-year-old's reward, not an illustration portfolio.
class CatView extends StatelessWidget {
  const CatView({
    required this.cat,
    this.mood = CatMood.pleased,
    this.size = 96,
    this.faded = false,
    super.key,
  });

  final Cat cat;
  final CatMood mood;
  final double size;

  /// A cat he has not met yet: drawn as a silhouette, so the collection shows
  /// how many friends are still to come without revealing them.
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CatPainter(cat: cat, mood: mood, faded: faded),
        isComplex: false,
      ),
    );
  }
}

class _CatPainter extends CustomPainter {
  _CatPainter({required this.cat, required this.mood, required this.faded});

  final Cat cat;
  final CatMood mood;
  final bool faded;

  static const Color _outline = Color(0xFF2B2F36);
  static const Color _pink = Color(0xFFE6A0A8);
  static const Color _hidden = Color(0xFFC9CDD4);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height);
    if (s <= 0) return;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    final Color coat = faded ? _hidden : cat.coat;
    final Color marking = faded ? _hidden : cat.marking;
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round
      ..color = faded ? const Color(0xFFB2B7BE) : _outline;

    // Head, a touch wider than tall — reads as a cat rather than a circle.
    final Rect head = Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.56),
      width: s * 0.66,
      height: s * 0.60,
    );

    _drawEars(canvas, s, head, coat, marking, line);
    canvas.drawOval(head, Paint()..color = coat);
    if (!faded) _drawPattern(canvas, s, head, marking);
    canvas.drawOval(head, line);
    _drawFace(canvas, s, head, line);

    canvas.restore();
  }

  void _drawEars(
    Canvas canvas,
    double s,
    Rect head,
    Color coat,
    Color marking,
    Paint line,
  ) {
    for (final double dir in <double>[-1, 1]) {
      final Offset base = Offset(
        head.center.dx + dir * s * 0.24,
        head.top + s * 0.06,
      );
      final Path ear = Path()
        ..moveTo(base.dx - s * 0.10, base.dy + s * 0.04)
        ..lineTo(base.dx + dir * s * 0.06, base.dy - s * 0.17)
        ..lineTo(base.dx + s * 0.10, base.dy + s * 0.04)
        ..close();
      canvas.drawPath(ear, Paint()..color = coat);
      canvas.drawPath(ear, line);
      // Inner ear.
      final Path inner = Path()
        ..moveTo(base.dx - s * 0.045, base.dy + s * 0.015)
        ..lineTo(base.dx + dir * s * 0.045, base.dy - s * 0.095)
        ..lineTo(base.dx + s * 0.045, base.dy + s * 0.015)
        ..close();
      canvas.drawPath(inner, Paint()..color = faded ? _hidden : _pink);
    }
  }

  /// Coat markings. Clipped to the head so nothing spills over the outline.
  void _drawPattern(Canvas canvas, double s, Rect head, Color marking) {
    canvas.save();
    canvas.clipPath(Path()..addOval(head));
    final Paint fill = Paint()..color = marking;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round
      ..color = marking;

    switch (cat.pattern) {
      case CatPattern.plain:
        break;
      case CatPattern.tabby:
        // Three brow stripes, the classic tabby "M".
        for (int i = -1; i <= 1; i++) {
          final double x = head.center.dx + i * s * 0.085;
          canvas.drawLine(
            Offset(x, head.top + s * 0.055),
            Offset(x + i * s * 0.02, head.top + s * 0.155),
            stroke,
          );
        }
      case CatPattern.patch:
        // A patch over one eye and ear.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              head.center.dx - s * 0.15,
              head.center.dy - s * 0.10,
            ),
            width: s * 0.30,
            height: s * 0.30,
          ),
          fill,
        );
      case CatPattern.tuxedo:
        // White bib and muzzle.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(head.center.dx, head.bottom - s * 0.02),
            width: s * 0.40,
            height: s * 0.34,
          ),
          fill,
        );
      case CatPattern.mitts:
        // Pale muzzle only.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(head.center.dx, head.center.dy + s * 0.12),
            width: s * 0.34,
            height: s * 0.22,
          ),
          fill,
        );
    }
    canvas.restore();
  }

  void _drawFace(Canvas canvas, double s, Rect head, Paint line) {
    final double eyeY = head.center.dy - s * 0.02;
    final double eyeDx = s * 0.13;
    final Color eyeColour = faded ? _hidden : cat.eyes;

    for (final double dir in <double>[-1, 1]) {
      final Offset centre = Offset(head.center.dx + dir * eyeDx, eyeY);
      switch (mood) {
        case CatMood.pleased:
          canvas.drawOval(
            Rect.fromCenter(
              center: centre,
              width: s * 0.105,
              height: s * 0.125,
            ),
            Paint()..color = eyeColour,
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: centre,
              width: s * 0.038,
              height: s * 0.095,
            ),
            Paint()..color = _outline,
          );
        case CatMood.delighted:
          // Eyes squeezed happily shut: an upward arc.
          final Path arc = Path()
            ..moveTo(centre.dx - s * 0.06, centre.dy + s * 0.03)
            ..quadraticBezierTo(
              centre.dx,
              centre.dy - s * 0.07,
              centre.dx + s * 0.06,
              centre.dy + s * 0.03,
            );
          canvas.drawPath(arc, line);
        case CatMood.sleepy:
          final Path lid = Path()
            ..moveTo(centre.dx - s * 0.055, centre.dy)
            ..quadraticBezierTo(
              centre.dx,
              centre.dy + s * 0.06,
              centre.dx + s * 0.055,
              centre.dy,
            );
          canvas.drawPath(lid, line);
      }
    }

    // Nose.
    final double noseY = head.center.dy + s * 0.11;
    final Path nose = Path()
      ..moveTo(head.center.dx - s * 0.035, noseY - s * 0.018)
      ..lineTo(head.center.dx + s * 0.035, noseY - s * 0.018)
      ..lineTo(head.center.dx, noseY + s * 0.028)
      ..close();
    canvas.drawPath(nose, Paint()..color = faded ? _hidden : _pink);
    canvas.drawPath(nose, line..strokeWidth = s * 0.018);

    // Mouth: two small arcs under the nose.
    for (final double dir in <double>[-1, 1]) {
      final Path curve = Path()
        ..moveTo(head.center.dx, noseY + s * 0.03)
        ..quadraticBezierTo(
          head.center.dx + dir * s * 0.03,
          noseY + s * 0.075,
          head.center.dx + dir * s * 0.075,
          noseY + s * 0.045,
        );
      canvas.drawPath(curve, line);
    }

    // Whiskers.
    for (final double dir in <double>[-1, 1]) {
      for (int i = -1; i <= 1; i++) {
        final double y = noseY + s * 0.015 + i * s * 0.045;
        canvas.drawLine(
          Offset(head.center.dx + dir * s * 0.10, y),
          Offset(head.center.dx + dir * s * 0.30, y + i * s * 0.025),
          line,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CatPainter old) =>
      old.cat != cat || old.mood != mood || old.faded != faded;
}

/// A paw print, used as the per-round accuracy marker.
///
/// Deliberately **not** a cat face. The cats are the collection — a thing he
/// keeps — and using the same picture for "how this round went" would mean two
/// different things by one image on a single screen. A paw is unmistakably
/// catty and unmistakably not a friend he has met.
class PawPrint extends StatelessWidget {
  const PawPrint({required this.filled, this.size = 44, super.key});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PawPainter(filled: filled)),
    );
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter({required this.filled});

  final bool filled;

  static const Color _earned = Color(0xFFD9793F);
  static const Color _empty = Color(0xFFD5D8DE);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height);
    if (s <= 0) return;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    final Paint paint = Paint()..color = filled ? _earned : _empty;

    // Main pad.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 0.66),
        width: s * 0.52,
        height: s * 0.44,
      ),
      paint,
    );

    // Four toes, fanned above it.
    const List<List<double>> toes = <List<double>>[
      <double>[0.24, 0.40, 0.17, 0.22],
      <double>[0.41, 0.28, 0.18, 0.24],
      <double>[0.59, 0.28, 0.18, 0.24],
      <double>[0.76, 0.40, 0.17, 0.22],
    ];
    for (final List<double> t in toes) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * t[0], s * t[1]),
          width: s * t[2],
          height: s * t[3],
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PawPainter old) => old.filled != filled;
}
