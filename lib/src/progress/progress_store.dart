import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'progress.dart';

/// Where progress is kept between sessions.
///
/// An interface, so the exercise never depends on a plugin and the tests never
/// need a device. It is also the single place that touches storage at all,
/// which is what makes "nothing leaves the tablet" (RFC-0001 D10) checkable
/// rather than merely intended.
abstract class ProgressStore {
  Future<Progress> load();
  Future<void> save(Progress progress);
}

/// Keeps progress in memory only. Used by tests, and a safe fallback.
class InMemoryProgressStore implements ProgressStore {
  InMemoryProgressStore([this._progress = const Progress()]);

  Progress _progress;

  @override
  Future<Progress> load() async => _progress;

  @override
  Future<void> save(Progress progress) async => _progress = progress;
}

/// Stores progress on the device, as a single JSON document.
///
/// One learner, one device, no account and no network. A JSON blob in shared
/// preferences is the whole persistence story — a database would be more
/// machinery than a few dozen rounds justify.
class SharedPreferencesProgressStore implements ProgressStore {
  static const String _key = 'jem_notes.progress.v1';

  @override
  Future<Progress> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const Progress();
    try {
      return Progress.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      // Corrupt or from a future version: start over rather than crash on
      // launch. Losing a streak is a bad day; a child who cannot open the app
      // at all is the end of the habit.
      return const Progress();
    }
  }

  @override
  Future<void> save(Progress progress) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }
}
