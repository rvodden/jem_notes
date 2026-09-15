import 'dart:async';

import 'package:flutter/material.dart';

import '../cats/cat.dart';
import '../cats/cat_view.dart';
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
            if (progress != null)
              _Companion(progress: progress, record: record),
            Text('Well done', style: text.displaySmall),
            const SizedBox(height: 14),
            if (record != null) _Paws(count: record.stars),
            if (record != null) const SizedBox(height: 14),
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
            if (progress != null && progress.newCats.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              _NewFriends(rewards: progress.newCats),
            ],
            const SizedBox(height: 28),
            FilledButton(onPressed: _start, child: const Text('Go again')),
            if (progress != null) ...<Widget>[
              const SizedBox(height: 26),
              _Collection(progress: progress),
            ],
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
          child: _ProgressTrail(
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

/// Where he is in the round: a trail of paw prints, filling as he goes.
///
/// Not a number and not a clock. A six-year-old reads "how much is left" off a
/// row of marks far faster than off "4 / 12", and a fraction quietly invites
/// hurrying — which is the opposite of what this exercise wants while accuracy
/// is still being built.
class _ProgressTrail extends StatelessWidget {
  const _ProgressTrail({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (int i = 0; i < total; i++) PawPrint(filled: i < done, size: 22),
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

/// How the round went, in paw prints. Accuracy only — there is no clock.
class _Paws extends StatelessWidget {
  const _Paws({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: PawPrint(filled: i < count, size: 44),
          ),
      ],
    );
  }
}

/// The cat that keeps him company: whichever friend he met most recently.
///
/// Always pleased to see him, and *delighted* after a perfect round — never
/// anything less. A mascot that looks disappointed is a guilt lever, and the
/// documented harm is children managing anxiety rather than learning
/// (DEC-0007). There is no mood available here that could express it.
class _Companion extends StatelessWidget {
  const _Companion({required this.progress, required this.record});

  final ProgressController progress;
  final RoundRecord? record;

  @override
  Widget build(BuildContext context) {
    final List<CatReward> cats = progress.cats;
    if (cats.isEmpty) return const SizedBox.shrink();
    final CatReward companion = progress.newCats.isNotEmpty
        ? progress.newCats.last
        : cats.last;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: <Widget>[
          CatView(
            cat: companion.cat,
            mood: (record?.stars ?? 0) == 3
                ? CatMood.delighted
                : CatMood.pleased,
            size: 116,
          ),
          const SizedBox(height: 4),
          Text(
            companion.cat.name,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

/// Announces cats that arrived because of this round.
class _NewFriends extends StatelessWidget {
  const _NewFriends({required this.rewards});

  final List<CatReward> rewards;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        for (final CatReward reward in rewards)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              children: <Widget>[
                Text(
                  'You met ${reward.cat.name}!',
                  style: text.titleLarge,
                  textAlign: TextAlign.center,
                ),
                Text(
                  reward.description,
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Every cat, met and unmet.
///
/// Unmet cats are drawn as silhouettes rather than hidden, so he can see how
/// many friends are still out there without being shown who they are.
class _Collection extends StatelessWidget {
  const _Collection({required this.progress});

  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    final Set<String> met = progress.cats
        .map((CatReward r) => r.cat.id)
        .toSet();
    final CatReward? next = progress.nextCat;
    return Column(
      children: <Widget>[
        Text(
          'Your cats — ${met.length} of ${CatCatalogue.all.length}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 2,
          runSpacing: 2,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final CatReward reward in CatCatalogue.all)
              Semantics(
                label: met.contains(reward.cat.id)
                    ? reward.cat.name
                    : 'a cat you have not met yet',
                child: CatView(
                  cat: reward.cat,
                  size: 40,
                  faded: !met.contains(reward.cat.id),
                ),
              ),
          ],
        ),
        if (next != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Next friend: ${next.hint}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
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
