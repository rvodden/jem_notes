import 'dart:async';

import 'package:flutter/material.dart';

import '../keyboard/piano_key.dart';
import '../progress/progress.dart';
import '../progress/progress_controller.dart';
import '../keyboard/piano_keyboard.dart';
import '../music/pitch.dart';
import '../staff/staff_view.dart';
import 'exercise_round.dart';
import 'level.dart';

/// How long the correct answer stays on screen after a wrong one.
///
/// Long enough to register, short enough not to feel like a telling-off.
const Duration kRevealDuration = Duration(milliseconds: 1100);

/// The exercise: see a note, find it on the keyboard, then name it.
///
/// Opens straight into a round — no menu, no tutorial, no settings — because
/// the whole budget is five minutes between lessons (RFC-0001 D13).
class ExercisePage extends StatefulWidget {
  const ExercisePage({
    this.level,
    this.progress,
    this.roundLength = kDefaultRoundLength,
    this.revealDuration = kRevealDuration,
    super.key,
  });

  final Level? level;

  /// Progress across sessions. Without one the exercise still runs — it just
  /// forgets everything, which is what the widget tests want.
  final ProgressController? progress;
  final int roundLength;

  /// Overridable so tests need not wait out the reveal in real time.
  final Duration revealDuration;

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  late ExerciseRound _round;
  Timer? _revealTimer;
  Level? _chosenLevel;
  RoundRecord? _lastRecord;
  bool _recording = false;

  ProgressController? get _progress => widget.progress;

  /// The level a new round should use: whatever he last chose, else the
  /// highest he has unlocked, else level 1.
  Level get _levelForRound =>
      widget.level ??
      _chosenLevel ??
      Level.byNumber(_progress?.highestUnlockedLevel ?? 1) ??
      Level.one;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _revealTimer?.cancel();
    _lastRecord = null;
    final Level level = _levelForRound;
    _round = ExerciseRound(
      level: level,
      roundLength: widget.roundLength,
      initialMissCounts:
          _progress?.missCountsFor(level) ?? const <Pitch, int>{},
    )..addListener(_onRoundChanged);
    setState(() {});
  }

  void _onRoundChanged() {
    if (_round.isRevealing && _revealTimer == null) {
      _revealTimer = Timer(widget.revealDuration, () {
        _revealTimer = null;
        _round.dismissReveal();
      });
    }
    if (_round.isComplete && !_recording && _lastRecord == null) {
      _recordFinishedRound();
    }
    setState(() {});
  }

  Future<void> _recordFinishedRound() async {
    final ProgressController? progress = _progress;
    if (progress == null) return;
    _recording = true;
    final RoundRecord record = await progress.recordRound(_round);
    _recording = false;
    if (!mounted) return;
    setState(() => _lastRecord = record);
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _round
      ..removeListener(_onRoundChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _round.isComplete
            ? _buildSummary(context)
            : _buildRound(context),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final RoundSummary summary = _round.summary;
    final TextTheme text = Theme.of(context).textTheme;
    final RoundRecord? record = _lastRecord;
    final ProgressController? progress = _progress;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Well done', style: text.displaySmall),
            const SizedBox(height: 16),
            if (record != null) _Stars(count: record.stars),
            if (record != null) const SizedBox(height: 16),
            Text(
              'You got ${summary.firstTimeCorrect} of ${summary.asked} '
              'right first time.',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (progress != null && progress.streak > 0) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                progress.streak == 1
                    ? 'First day of practice'
                    : '${progress.streak} days in a row',
                style: text.bodyLarge,
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(onPressed: _start, child: const Text('Go again')),
            if (progress != null &&
                progress.unlockedLevels.length > 1) ...<Widget>[
              const SizedBox(height: 28),
              _LevelChooser(
                levels: progress.unlockedLevels,
                selected: _levelForRound.number,
                onSelected: (Level level) {
                  setState(() => _chosenLevel = level);
                  _start();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRound(BuildContext context) {
    final round = _round;
    final question = round.current!;
    final bool locating = round.step == AnswerStep.locate;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _ProgressDots(
            total: round.questionTarget,
            done: round.questionNumber - 1,
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: StaffView(pitch: question.pitch, clef: question.clef),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: locating
                ? Text(
                    'Find it on the keyboard',
                    style: Theme.of(context).textTheme.titleMedium,
                  )
                : _LetterButtons(
                    letters: round.letterOptions,
                    revealed: round.reveal == Reveal.correctName
                        ? question.pitch.letter
                        : null,
                    onPressed: round.submitLetter,
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: SizedBox(
            height: 170,
            child: PianoKeyboard(
              // The keyboard only accepts input during the locate step; during
              // naming it stays on screen as context but is inert.
              activePitches: locating && !round.isRevealing
                  ? round.level.pitchSet
                  : const <Pitch>{},
              revealedPitch: round.reveal == Reveal.correctKey
                  ? question.pitch
                  : null,
              onKeyPressed: (PianoKey key) => round.submitKey(key),
            ),
          ),
        ),
      ],
    );
  }
}

/// Where he is in the round. Dots rather than "4 / 12" — a six-year-old reads
/// a row of dots faster than a fraction, and it carries no sense of a clock.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final Color on = Theme.of(context).colorScheme.primary;
    final Color off = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: i < done ? on : off,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _LetterButtons extends StatelessWidget {
  const _LetterButtons({
    required this.letters,
    required this.revealed,
    required this.onPressed,
  });

  final List<NoteLetter> letters;
  final NoteLetter? revealed;
  final ValueChanged<NoteLetter> onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Rendered in the order given, NOT sorted: the round shuffles them so the
    // buttons cannot be answered by position instead of by reading.
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (final NoteLetter letter in letters)
          SizedBox(
            width: 84,
            height: 84,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: letter == revealed
                    ? const Color(0xFFA8D5BA)
                    : scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                shape: const CircleBorder(),
                // Derived from the theme rather than a bare TextStyle, so the
                // letters inherit the app's font family instead of falling back
                // to whatever the platform supplies.
                textStyle: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              onPressed: revealed != null ? null : () => onPressed(letter),
              child: Text(letter.displayLabel),
            ),
          ),
      ],
    );
  }
}

/// Stars for the round just finished. Accuracy only — there is no clock.
class _Stars extends StatelessWidget {
  const _Stars({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < count ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 48,
              color: i < count
                  ? const Color(0xFFE9A93C)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

/// Picks which level the next round uses.
///
/// Only ever shows unlocked levels: a locked one is not rendered at all, so
/// there is nothing to tap hopefully and nothing to explain. It appears only
/// once there is a choice to make.
class _LevelChooser extends StatelessWidget {
  const _LevelChooser({
    required this.levels,
    required this.selected,
    required this.onSelected,
  });

  final List<Level> levels;
  final int selected;
  final ValueChanged<Level> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('Level', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final Level level in levels)
              ChoiceChip(
                label: Text('${level.number}'),
                selected: level.number == selected,
                onSelected: (_) => onSelected(level),
              ),
          ],
        ),
      ],
    );
  }
}
