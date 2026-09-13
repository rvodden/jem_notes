import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'src/exercise/exercise_page.dart';
import 'src/keyboard/keyboard_harness_page.dart';
import 'src/progress/progress_controller.dart';
import 'src/progress/progress_store.dart';
import 'src/staff/staff_harness_page.dart';

void main() {
  runApp(
    JemNotesApp(
      progress: ProgressController(store: SharedPreferencesProgressStore()),
    ),
  );
}

/// Root of the app.
class JemNotesApp extends StatefulWidget {
  const JemNotesApp({required this.progress, super.key});

  static const String title = 'Jem Notes';

  final ProgressController progress;

  @override
  State<JemNotesApp> createState() => _JemNotesAppState();
}

class _JemNotesAppState extends State<JemNotesApp> {
  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_onProgressChanged);
    widget.progress.load();
  }

  void _onProgressChanged() => setState(() {});

  @override
  void dispose() {
    widget.progress.removeListener(_onProgressChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: JemNotesApp.title,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      // Straight into a round: no menu, no tutorial, nothing to choose. The
      // whole budget is five minutes between lessons (RFC-0001 D13).
      //
      // While progress loads, the exercise is simply not built yet — a round
      // started before it arrives would use level 1 and forget its result.
      home: widget.progress.isLoaded
          ? _Home(progress: widget.progress)
          : const _Loading(),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Home extends StatelessWidget {
  const _Home({required this.progress});

  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ExercisePage(progress: progress),
        // Developer affordance only, absent from release builds: the two
        // renderer harnesses, for checking the staff against real sheet music
        // and trying the keyboard's hit targets with a real finger.
        if (kDebugMode)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.bug_report_outlined, size: 18),
                tooltip: 'Developer harnesses',
                onSelected: (String value) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => value == 'staff'
                          ? const StaffHarnessPage()
                          : const KeyboardHarnessPage(),
                    ),
                  );
                },
                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'staff',
                    child: Text('Staff renderer'),
                  ),
                  PopupMenuItem<String>(
                    value: 'keyboard',
                    child: Text('Keyboard'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
