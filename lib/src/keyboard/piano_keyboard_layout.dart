import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../music/pitch.dart';
import 'piano_key.dart';

/// Where one key sits.
@immutable
class KeyPlacement {
  const KeyPlacement(this.key, this.rect);

  final PianoKey key;
  final Rect rect;
}

/// Geometry of a fixed-extent piano keyboard.
///
/// RFC-0001 D3 fixes the extent at C3-C5 from level 1 onward. The keyboard's
/// shape therefore never changes as levels widen the notes asked — early levels
/// simply leave most keys inactive. That matters because the child is building
/// a spatial map of where notes live, and a map is useless if the territory
/// moves under it.
@immutable
class PianoKeyboardLayout {
  PianoKeyboardLayout({
    required this.size,
    Pitch lowest = const Pitch(NoteLetter.c, 3),
    Pitch highest = const Pitch(NoteLetter.c, 5),
  }) : whiteKeys = <KeyPlacement>[],
       blackKeys = <KeyPlacement>[] {
    final List<Pitch> naturals = Pitch.range(lowest, highest);
    final double whiteWidth = size.width / naturals.length;
    final double blackWidth = whiteWidth * _blackWidthRatio;
    final double blackHeight = size.height * _blackHeightRatio;

    for (int i = 0; i < naturals.length; i++) {
      whiteKeys.add(
        KeyPlacement(
          PianoKey.white(naturals[i]),
          Rect.fromLTWH(i * whiteWidth, 0, whiteWidth, size.height),
        ),
      );
    }

    // A black key straddles the boundary between two white keys, so the last
    // white key never has one: there is no white key to its right to straddle.
    for (int i = 0; i < naturals.length - 1; i++) {
      final PianoKey candidate = PianoKey.black(naturals[i]);
      if (!candidate.hasBlackAbove) continue;
      final double centre = (i + 1) * whiteWidth;
      blackKeys.add(
        KeyPlacement(
          candidate,
          Rect.fromLTWH(centre - blackWidth / 2, 0, blackWidth, blackHeight),
        ),
      );
    }
  }

  /// Black keys are narrower and shorter than white ones, as on a real piano.
  static const double _blackWidthRatio = 0.58;
  static const double _blackHeightRatio = 0.62;

  final Size size;
  final List<KeyPlacement> whiteKeys;
  final List<KeyPlacement> blackKeys;

  double get whiteKeyWidth =>
      whiteKeys.isEmpty ? 0 : whiteKeys.first.rect.width;

  /// The key under [point], or null if the tap missed the keyboard entirely.
  ///
  /// Black keys are tested first because they are drawn on top: in the region
  /// where a black key overlaps the white key behind it, a tap belongs to the
  /// black key. Testing white first would make the top third of every black key
  /// silently answer with its neighbour.
  KeyPlacement? hitTest(Offset point) {
    for (final KeyPlacement placement in blackKeys) {
      if (placement.rect.contains(point)) return placement;
    }
    for (final KeyPlacement placement in whiteKeys) {
      if (placement.rect.contains(point)) return placement;
    }
    return null;
  }
}
