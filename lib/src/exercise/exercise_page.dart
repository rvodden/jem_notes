import 'dart:async';

import 'package:flutter/material.dart';

import '../keyboard/piano_key.dart';
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
    this.roundLength = kDefaultRoundLength,
    this.revealDuration = kRevealDuration,
    super.key,
  });

  final Level? level;
  final int roundLength;

  /// Overridable so tests need not wait out the reveal in real time.
  final Duration revealDuration;

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  late ExerciseRound _round;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _revealTimer?.cancel();
    _round = ExerciseRound(
      level: widget.level ?? Level.one,
      roundLength: widget.roundLength,
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
    setState(() {});
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Well done', style: text.displaySmall),
            const SizedBox(height: 12),
            Text(
              'You got ${summary.firstTimeCorrect} of ${summary.asked} '
              'right first time.',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(onPressed: _start, child: const Text('Go again')),
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
                    letters: round.level.pitches
                        .map((Pitch p) => p.letter)
                        .toSet()
                        .toList(),
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
    final List<NoteLetter> sorted = <NoteLetter>[...letters]
      ..sort((NoteLetter a, NoteLetter b) => a.label.compareTo(b.label));
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (final NoteLetter letter in sorted)
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
                textStyle: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: revealed != null ? null : () => onPressed(letter),
              child: Text(letter.label),
            ),
          ),
      ],
    );
  }
}
