import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'src/exercise/exercise_page.dart';
import 'src/keyboard/keyboard_harness_page.dart';
import 'src/staff/staff_harness_page.dart';

void main() => runApp(const JemNotesApp());

/// Root of the app.
class JemNotesApp extends StatelessWidget {
  const JemNotesApp({super.key});

  static const String title = 'Jem Notes';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      // Straight into a round: no menu, no tutorial, nothing to choose.
      // The whole budget is five minutes between lessons (RFC-0001 D13), and a
      // six-year-old should not have to read his way past a home screen to
      // start practising.
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const ExercisePage(),
        // Developer affordance only, and absent from release builds: the two
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
