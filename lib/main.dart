import 'package:flutter/material.dart';

void main() => runApp(const JemNotesApp());

/// Root of the app.
///
/// Deliberately thin: the first exercise (identify a note's letter name and
/// its position on a piano keyboard) lands as its own widget behind this
/// shell, so this file stays a wiring point rather than growing UI of its own.
class JemNotesApp extends StatelessWidget {
  const JemNotesApp({super.key});

  static const String title = 'Jem Notes';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

/// Placeholder landing screen, replaced by the exercise picker once there is
/// more than one exercise to pick from.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(JemNotesApp.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Learn to read music', style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'First exercise: name the note, then find it on the keyboard.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
