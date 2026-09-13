---
id: JEM-2
title: Piano keyboard widget, C3-C5, with active and inactive keys
status: To Do
priority: high
references:
  - spec/rfcs/RFC-0001-note-reading-app-design.md
dependencies: []
labels:
  - renderer
---

## Context

RFC-0001 D3 fixes the keyboard at two octaves, C3–C5, from level 1 onward, with
most keys inactive early on. The reason it is fixed rather than growing: the
keyboard's geometry must not move while he is building a spatial map of it, and a
fixed extent means no relayout when later levels widen the note set.

RFC-0001 D2 settles that keys carry **no letter labels** during a round — with
labels, naming a note after locating it would be free (OQ-2).

RFC-0001 phase 2. Independent of JEM-1; the two can be built in parallel.

## Scope

A `PianoKeyboard` widget drawing 15 white and 10 black keys spanning C3–C5, with
correct proportions and black-key offsets. Takes a set of active pitches; keys
outside that set render visibly inactive and do not respond to taps. Reports taps
as a scientific-pitch value via callback.

Hit targets are sized for a 6-year-old (RFC-0001 D12: tablet primary, phone
supported) — black keys must be tappable without accidentally hitting the white
key behind them.

**Out of scope:** the staff, answer checking, audio, labels, scrolling, any state.

## Acceptance criteria

- [ ] Renders 15 white and 10 black keys spanning C3–C5, in correct piano layout
      (no black key between B–C or E–F)
- [ ] Black keys are drawn above white keys and a tap in the overlap region
      registers the black key, not the white one
- [ ] Tapping a key invokes the callback exactly once with that key's pitch
- [ ] Keys not in the active set are visually distinct and their taps invoke no
      callback
- [ ] No key displays a letter name
- [ ] At phone-portrait width every white key is at least 24 logical pixels wide;
      at tablet-landscape at least 40
- [ ] Golden tests at phone-portrait and tablet-landscape, each with the level-1
      active set {B3, C4, D4} and with all keys active
- [ ] Widget tests assert the black-key overlap case and that inactive keys
      swallow taps
- [ ] `flutter analyze` and `dart format --set-exit-if-changed` clean;
      `flutter test --coverage` passes

## Done state

`flutter test` includes passing golden tests at both sizes for both active sets,
plus widget tests for black-key hit precedence and inactive-key suppression.
