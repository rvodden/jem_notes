import 'package:flutter/material.dart';

import '../music/pitch.dart';
import 'piano_key.dart';
import 'piano_keyboard_layout.dart';

/// Colours for the keyboard, kept in one place so goldens and the app agree.
@immutable
class PianoKeyboardColors {
  const PianoKeyboardColors({
    this.whiteKey = const Color(0xFFFFFFFF),
    this.whiteKeyInactive = const Color(0xFFE7E7E4),
    this.blackKey = const Color(0xFF1A1C1F),
    this.outline = const Color(0xFF2B2F35),
  });

  final Color whiteKey;
  final Color whiteKeyInactive;
  final Color blackKey;
  final Color outline;
}

/// A two-octave piano keyboard, C3-C5, that reports which key was pressed.
///
/// Deliberately knows nothing about questions or answers: it renders keys,
/// says which one was tapped, and refuses taps on keys the caller has not made
/// active. RFC-0001 phase 2.
///
/// **No key is labelled.** RFC-0001 OQ-2: the exercise asks the child to locate
/// a note and *then* name it, so a letter printed on the key would hand him the
/// second answer for free. There is no label parameter to switch on.
class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({
    required this.activePitches,
    required this.onKeyPressed,
    this.colors = const PianoKeyboardColors(),
    super.key,
  });

  /// White keys that may be pressed. Everything else renders inactive and
  /// swallows taps.
  ///
  /// Black keys are never active: they have no name until accidentals arrive
  /// at level 9+, so nothing can currently ask for one.
  final Set<Pitch> activePitches;

  /// Called with the key the child pressed. Never fires for an inactive key.
  final ValueChanged<PianoKey> onKeyPressed;

  final PianoKeyboardColors colors;

  bool _isActive(PianoKey key) =>
      !key.isBlack && activePitches.contains(key.naturalBelow);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.isEmpty) return const SizedBox.shrink();
        final PianoKeyboardLayout layout = PianoKeyboardLayout(size: size);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (TapUpDetails details) {
            final KeyPlacement? hit = layout.hitTest(details.localPosition);
            if (hit == null || !_isActive(hit.key)) return;
            onKeyPressed(hit.key);
          },
          child: CustomPaint(
            painter: _KeyboardPainter(
              layout: layout,
              isActive: _isActive,
              colors: colors,
            ),
            size: size,
          ),
        );
      },
    );
  }
}

class _KeyboardPainter extends CustomPainter {
  _KeyboardPainter({
    required this.layout,
    required this.isActive,
    required this.colors,
  });

  final PianoKeyboardLayout layout;
  final bool Function(PianoKey) isActive;
  final PianoKeyboardColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = layout.whiteKeyWidth * 0.12;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colors.outline;

    // Whites first, then blacks on top — the same order the hit test reverses.
    for (final KeyPlacement placement in layout.whiteKeys) {
      final RRect key = RRect.fromRectAndCorners(
        placement.rect.deflate(0.5),
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      );
      canvas.drawRRect(
        key,
        Paint()
          ..color = isActive(placement.key)
              ? colors.whiteKey
              : colors.whiteKeyInactive,
      );
      canvas.drawRRect(key, stroke);
    }

    for (final KeyPlacement placement in layout.blackKeys) {
      final RRect key = RRect.fromRectAndCorners(
        placement.rect,
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      );
      // Black keys always render dark, never dimmed. No black key is
      // answerable before accidentals arrive at level 9+, so dimming them
      // would grey out two thirds of the instrument and make the keyboard read
      // as broken rather than as a piano — working against the recognition of
      // the real instrument that the whole exercise is aiming at. The
      // active/inactive signal is carried entirely by the white keys, which
      // are the ones that can actually be pressed.
      canvas.drawRRect(key, Paint()..color = colors.blackKey);
    }
  }

  @override
  bool shouldRepaint(_KeyboardPainter oldDelegate) =>
      oldDelegate.layout.size != layout.size ||
      oldDelegate.isActive != isActive ||
      oldDelegate.colors != colors;
}
