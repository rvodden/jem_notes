---
id: JEM-3
title: Exercise loop for level 1 - locate then name, with requeue on miss
status: To Do
priority: high
references:
  - spec/rfcs/RFC-0001-note-reading-app-design.md
dependencies:
  - JEM-1
  - JEM-2
labels:
  - exercise
---

## Context

RFC-0001 phase 3 — the first build he can actually try. Composes JEM-1's staff
and JEM-2's keyboard into a round.

Per RFC-0001: a question shows one note (D1), he locates it on the keyboard then
names it by letter (D2), a wrong answer is revealed without penalty and that note
is asked again later in the same round (D4), and the next note is chosen weighted
toward recently-missed ones (D7). No timer and no score (accuracy before speed).
The app opens straight into a round with a visible end (D13).

Level 1 only: note set {B3, C4, D4}.

## Scope

A round of N questions (N configurable, default 12 per RFC-0001 OQ-4) over the
level-1 note set. Each question: render the note, accept a key tap, then accept a
letter-name tap from three buttons. Wrong answers reveal the correct key or letter,
count as missed, and cause that pitch to be re-asked before the round ends. Round
ends on a summary screen showing how many were right first time.

C4 is notated as a treble-clef ledger line or a bass-clef ledger line, chosen at
random per question (RFC-0001 OQ-3 recommendation).

**Out of scope:** persistence, stars, streaks, levels beyond 1, audio, menus,
settings UI. No state survives app restart.

## Acceptance criteria

- [ ] App launches directly into a round — no menu, no tutorial, no settings
- [ ] Each question requires two answers in order: key first, then letter name
- [ ] Answering the key wrongly reveals the correct key, and the question still
      proceeds to the naming step
- [ ] A pitch answered wrongly at either step is asked again before the round ends
- [ ] A round of 12 questions ends in a summary showing first-time-correct count
- [ ] Over 200 simulated questions with one pitch always answered wrongly, that
      pitch is asked measurably more often than the other two (D7 weighting)
- [ ] C4 appears in both treble-ledger and bass-ledger notations across a round
- [ ] No timer, no countdown, no score, and no finger numbers appear anywhere
- [ ] Round length is a named constant or injected parameter, not scattered
      literals
- [ ] `flutter analyze` and `dart format --set-exit-if-changed` clean;
      `flutter test --coverage` passes

## Done state

`flutter test` includes a widget test driving a complete 12-question round end to
end, a test proving a missed pitch is requeued within the same round, and a
statistical test over 200 selections proving the miss weighting. An APK can be
sideloaded and a round completed on the tablet.
