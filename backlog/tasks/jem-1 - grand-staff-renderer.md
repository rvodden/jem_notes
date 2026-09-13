---
id: JEM-1
title: Render a single note on a grand staff, with ledger lines
status: To Do
priority: high
references:
  - spec/rfcs/RFC-0001-note-reading-app-design.md
dependencies: []
labels:
  - renderer
---

## Context

RFC-0001 D1 settles that notes are always shown on a braced grand staff, as they
appear in his method book. RFC-0001 phase 1. Nothing else can be built until a
note can be drawn correctly, and this is the only phase with no game logic in it.

The level-1 note set is B3, C4, D4 — which sit in the gap *between* the staves,
so **ledger lines are required immediately**, not as a later refinement:

- Treble clef: D4 is the space below the bottom line, C4 the first ledger line
  below, B3 below that
- Bass clef: B3 is the space above the top line, C4 a ledger line above

## Scope

A `StaffView` widget that draws a braced grand staff (treble + bass), both clefs,
and exactly one notehead at a caller-specified pitch, using `CustomPainter` and
the Bravura SMuFL font (SIL OFL, vendored under `assets/fonts/`).

Pitch is expressed as a scientific-pitch value (e.g. `C4`), and the widget maps
it to a vertical staff position and a clef. Where a pitch is renderable in both
clefs (C4), the caller chooses which.

**Out of scope:** the keyboard, answer handling, audio, accidentals, multiple
notes, rhythm/note durations, any state.

## Acceptance criteria

- [ ] `StaffView` renders a braced grand staff with treble and bass clefs, five
      lines each, at any widget size without clipping
- [ ] Given pitch `C4` and clef `treble`, the notehead is centred on a ledger
      line below the treble staff; given `C4` and clef `bass`, on a ledger line
      above the bass staff
- [ ] Given `B3`/`bass` the notehead sits in the space above the bass staff's top
      line; given `D4`/`treble` in the space below the treble staff's bottom line
- [ ] Every pitch in C3–C5 renders at a distinct vertical position, and positions
      increase monotonically with pitch
- [ ] Noteheads and clefs are drawn from Bravura glyphs, not hand-drawn shapes
- [ ] Golden tests cover B3, C4-treble, C4-bass and D4 at both phone-portrait and
      tablet-landscape sizes
- [ ] `flutter analyze` and `dart format --set-exit-if-changed` clean;
      `flutter test --coverage` passes
- [ ] No finger numbers are rendered anywhere (RFC-0001, the crux)

## Done state

`flutter test` includes passing golden tests for the four level-1 renderings at
two screen sizes, and a widget test asserting monotonic vertical positions across
C3–C5. A throwaway harness screen can display any pitch on request.
