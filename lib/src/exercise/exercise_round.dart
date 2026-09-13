import 'dart:math';

import 'package:flutter/foundation.dart';

import '../keyboard/piano_key.dart';
import '../music/pitch.dart';
import 'level.dart';
import 'pitch_selector.dart';
import 'question.dart';

/// Questions in a round. Sized so a round fits inside five minutes with slack
/// (RFC-0001 D13), at roughly two taps per question.
const int kDefaultRoundLength = 12;

/// Which half of a question he is answering.
///
/// Order is deliberate and settled in RFC-0001 OQ-2: locate the note on the
/// keyboard, *then* name it. The keys carry no labels, so the second answer is
/// not free.
enum AnswerStep { locate, name }

/// What is being shown back to him after an answer.
enum Reveal { none, correctKey, correctName }

@immutable
class RoundSummary {
  const RoundSummary({required this.asked, required this.firstTimeCorrect});

  /// Questions actually asked, which can exceed the round length when a miss
  /// on the final question had to be re-asked.
  final int asked;

  /// Questions where both halves were right at the first attempt.
  final int firstTimeCorrect;
}

/// One round of the exercise.
///
/// Holds no timer and no score. RFC-0001: he will be slower with letter names
/// than with finger numbers for a while, and that dip is when a child abandons
/// a new strategy — so nothing here counts down or marks him wrong in red.
/// A missed note is revealed, not punished, and quietly comes back.
class ExerciseRound extends ChangeNotifier {
  ExerciseRound({
    required this.level,
    this.roundLength = kDefaultRoundLength,
    Random? random,
  }) : _random = random ?? Random(),
       _selector = PitchSelector(pitches: level.pitches, random: random) {
    _askNext();
  }

  final Level level;
  final int roundLength;

  /// Most a round may be extended to fit re-asks: one extra pass over the
  /// level's notes. See [_askNext] for why this is capped at all.
  int get _maxExtraQuestions => level.pitches.length;
  final Random _random;
  final PitchSelector _selector;

  /// Notes missed and not yet re-asked. The round will not end while this has
  /// entries — see [_askNext].
  final Set<Pitch> _awaitingRequeue = <Pitch>{};

  Question? _current;
  AnswerStep _step = AnswerStep.locate;
  Reveal _reveal = Reveal.none;
  int _asked = 0;
  int _firstTimeCorrect = 0;
  bool _missedThisQuestion = false;
  int _target = 0;

  Question? get current => _current;
  AnswerStep get step => _step;
  Reveal get reveal => _reveal;
  bool get isRevealing => _reveal != Reveal.none;
  bool get isComplete => _current == null;
  int get asked => _asked;

  /// 1-based position of the current question, for a progress indicator.
  int get questionNumber => _asked;
  int get questionTarget => _target;

  RoundSummary get summary =>
      RoundSummary(asked: _asked, firstTimeCorrect: _firstTimeCorrect);

  /// The key he should press for the current question.
  Pitch? get expectedPitch => _current?.pitch;

  void _askNext() {
    _missedThisQuestion = false;
    _step = AnswerStep.locate;
    _reveal = Reveal.none;

    if (_target == 0) _target = roundLength;

    // A miss on the very last question cannot be re-asked inside the round, so
    // the round grows rather than breaking the promise that a missed note comes
    // back.
    //
    // That growth is capped, and the cap matters more than the promise: if a
    // note is missed again on each re-ask, an uncapped round never ends — and
    // it would trap precisely the child who is struggling most, in an exercise
    // whose whole design is built around not punishing him for the dip. Past
    // the cap the round simply ends with the re-ask outstanding; the note
    // carries its raised weight into the next round instead (D7).
    final int ceiling = roundLength + _maxExtraQuestions;
    if (_asked >= _target && _awaitingRequeue.isNotEmpty && _target < ceiling) {
      _target = (_asked + _awaitingRequeue.length).clamp(0, ceiling);
    }

    if (_asked >= _target) {
      _current = null;
      notifyListeners();
      return;
    }

    // Once there are only as many questions left as notes owed a re-ask, the
    // remaining slots belong to them.
    final int slotsLeft = _target - _asked;
    final Set<Pitch>? require =
        _awaitingRequeue.isNotEmpty && slotsLeft <= _awaitingRequeue.length
        ? Set<Pitch>.of(_awaitingRequeue)
        : null;

    final Pitch pitch = _selector.next(require: require);
    _awaitingRequeue.remove(pitch);
    _current = Question.forPitch(pitch, _random);
    _asked++;
    notifyListeners();
  }

  /// Records a key press during [AnswerStep.locate]. Ignored while revealing.
  void submitKey(PianoKey key) {
    if (_current == null || _step != AnswerStep.locate || isRevealing) return;
    if (key.pitch == _current!.pitch) {
      _step = AnswerStep.name;
      notifyListeners();
      return;
    }
    _recordMiss();
    // The question still proceeds to naming after the reveal: getting the key
    // wrong does not cost him the chance to name the note.
    _reveal = Reveal.correctKey;
    notifyListeners();
  }

  /// Records a letter press during [AnswerStep.name]. Ignored while revealing.
  void submitLetter(NoteLetter letter) {
    if (_current == null || _step != AnswerStep.name || isRevealing) return;
    if (letter == _current!.pitch.letter) {
      if (!_missedThisQuestion) {
        _firstTimeCorrect++;
        _selector.recordCorrect(_current!.pitch);
      }
      _askNext();
      return;
    }
    _recordMiss();
    _reveal = Reveal.correctName;
    notifyListeners();
  }

  void _recordMiss() {
    if (_current == null) return;
    _missedThisQuestion = true;
    _selector.recordMiss(_current!.pitch);
    _awaitingRequeue.add(_current!.pitch);
  }

  /// Called when the reveal has been on screen long enough.
  void dismissReveal() {
    if (!isRevealing) return;
    if (_reveal == Reveal.correctKey) {
      _reveal = Reveal.none;
      _step = AnswerStep.name;
      notifyListeners();
      return;
    }
    _askNext();
  }
}
