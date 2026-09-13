import 'package:flutter/material.dart';

import '../music/pitch.dart';
import 'piano_key.dart';
import 'piano_keyboard.dart';

/// Development harness for [PianoKeyboard]: shows the level-1 active set and
/// echoes the last key pressed.
///
/// Not part of the exercise. It exists so the hit targets can be tried with a
/// real six-year-old finger on the real tablet, which is the only way to find
/// out whether the black keys are reachable without mis-taps.
class KeyboardHarnessPage extends StatefulWidget {
  const KeyboardHarnessPage({super.key});

  @override
  State<KeyboardHarnessPage> createState() => _KeyboardHarnessPageState();
}

class _KeyboardHarnessPageState extends State<KeyboardHarnessPage> {
  /// RFC-0001 level 1: B, middle C, D.
  static final Set<Pitch> _level1 = <Pitch>{
    Pitch.parse('B3'),
    Pitch.middleC,
    Pitch.parse('D4'),
  };

  static final Set<Pitch> _allWhite = Pitch.range(
    Pitch.parse('C3'),
    Pitch.parse('C5'),
  ).toSet();

  bool _allActive = false;
  PianoKey? _last;

  @override
  Widget build(BuildContext context) {
    final Set<Pitch> active = _allActive ? _allWhite : _level1;
    return Scaffold(
      appBar: AppBar(title: const Text('Keyboard')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                _last == null
                    ? 'Press a key'
                    : _last!.naturalBelow.letter.label,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(value: false, label: Text('Level 1')),
                ButtonSegment<bool>(value: true, label: Text('All white keys')),
              ],
              selected: <bool>{_allActive},
              onSelectionChanged: (Set<bool> s) =>
                  setState(() => _allActive = s.first),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: PianoKeyboard(
                activePitches: active,
                onKeyPressed: (PianoKey key) => setState(() => _last = key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
