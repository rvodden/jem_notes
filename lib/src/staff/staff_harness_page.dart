import 'package:flutter/material.dart';

import '../music/clef.dart';
import '../music/pitch.dart';
import 'staff_geometry.dart';
import 'staff_view.dart';

/// Development harness for [StaffView]: steps through every pitch in the
/// C3-C5 range and lets the clef be switched where both are legal.
///
/// Not part of the exercise. It exists so a human can eyeball the renderer
/// against real sheet music, which is the only way to catch a note that is
/// technically at a distinct position but conventionally written wrong.
class StaffHarnessPage extends StatefulWidget {
  const StaffHarnessPage({super.key});

  @override
  State<StaffHarnessPage> createState() => _StaffHarnessPageState();
}

class _StaffHarnessPageState extends State<StaffHarnessPage> {
  static final List<Pitch> _pitches = Pitch.range(
    const Pitch(NoteLetter.c, 3),
    const Pitch(NoteLetter.c, 5),
  );

  int _index = _pitches.indexOf(Pitch.middleC);
  Clef? _override;

  Pitch get _pitch => _pitches[_index];
  Clef get _clef => _override ?? StaffGeometry.defaultClefFor(_pitch);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_pitch.scientificName} · ${_clef.name}')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StaffView(pitch: _pitch, clef: _clef),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: <Widget>[
              IconButton.filledTonal(
                onPressed: _index > 0 ? () => setState(() => _index--) : null,
                icon: const Icon(Icons.arrow_downward),
              ),
              IconButton.filledTonal(
                onPressed: _index < _pitches.length - 1
                    ? () => setState(() => _index++)
                    : null,
                icon: const Icon(Icons.arrow_upward),
              ),
              SegmentedButton<Clef?>(
                segments: const <ButtonSegment<Clef?>>[
                  ButtonSegment<Clef?>(value: null, label: Text('auto')),
                  ButtonSegment<Clef?>(
                    value: Clef.treble,
                    label: Text('treble'),
                  ),
                  ButtonSegment<Clef?>(value: Clef.bass, label: Text('bass')),
                ],
                selected: <Clef?>{_override},
                onSelectionChanged: (Set<Clef?> s) =>
                    setState(() => _override = s.first),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
