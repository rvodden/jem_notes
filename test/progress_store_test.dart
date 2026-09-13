import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RoundRecord aRound({int day = 13, int correct = 12}) => RoundRecord(
    level: 1,
    day: DateTime(2026, 9, day),
    asked: 12,
    firstTimeCorrect: correct,
  );

  group('on-device store', () {
    test('writes and reads progress back', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferencesProgressStore store =
          SharedPreferencesProgressStore();

      expect((await store.load()).rounds, isEmpty);

      await store.save(
        Progress(
          rounds: <RoundRecord>[aRound()],
          pitchStats: <String, PitchStat>{
            'C4': const PitchStat(asked: 4, missed: 1),
          },
        ),
      );

      final Progress loaded = await store.load();
      expect(loaded.rounds, <RoundRecord>[aRound()]);
      expect(loaded.pitchStats['C4'], const PitchStat(asked: 4, missed: 1));
    });

    test('a fresh device starts empty rather than throwing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect((await SharedPreferencesProgressStore().load()).streak, 0);
    });

    test(
      'corrupt stored data starts over instead of crashing on launch',
      () async {
        // Losing a streak is a bad day. A child who cannot open the app at all
        // is the end of the habit — so this path must never throw.
        SharedPreferences.setMockInitialValues(<String, Object>{
          'jem_notes.progress.v1': 'not json at all {{{',
        });
        final Progress loaded = await SharedPreferencesProgressStore().load();
        expect(loaded.rounds, isEmpty);
      },
    );

    test(
      'data from a future version starts over rather than half-loading',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'jem_notes.progress.v1':
              '{"version":99,"rounds":[{"unexpected":"shape"}]}',
        });
        final Progress loaded = await SharedPreferencesProgressStore().load();
        expect(loaded.rounds, isEmpty);
      },
    );

    test('an empty string is treated as no data', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'jem_notes.progress.v1': '',
      });
      expect((await SharedPreferencesProgressStore().load()).rounds, isEmpty);
    });
  });

  group('in-memory store', () {
    test('round-trips, for tests and as a safe fallback', () async {
      final InMemoryProgressStore store = InMemoryProgressStore();
      expect((await store.load()).rounds, isEmpty);
      await store.save(Progress(rounds: <RoundRecord>[aRound()]));
      expect((await store.load()).rounds, hasLength(1));
    });

    test('can be seeded, which is what makes UI states testable', () async {
      final InMemoryProgressStore store = InMemoryProgressStore(
        Progress(rounds: <RoundRecord>[aRound(day: 11), aRound(day: 12)]),
      );
      final Progress loaded = await store.load();
      expect(loaded.highestUnlockedLevel, 2);
    });
  });
}
