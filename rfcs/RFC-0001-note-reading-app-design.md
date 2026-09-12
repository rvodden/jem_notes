---
id: RFC-0001
title: "Note-reading app: design and level ladder"
status: Draft
author: Richard Vodden
created: 2026-09-12
---

# RFC: Note-reading app: design and level ladder

**Status:** Draft
**Author:** Richard Vodden
**Created:** 2026-09-12

## Summary

Defines how the app teaches, for one specific 6-year-old learner, before any
exercise is built. The core loop is: a single note on a grand staff, which he
locates on an on-screen piano keyboard and then names by letter. Progress is a
ladder of levels that starts at three notes (B–C–D around middle C) and widens
to the two-octave C3–C5 range his method book reaches. Settled in an interview
on 2026-09-12; framework choice is separate, in DEC-0001.

## Background

### The learner

Six years old, two years of lessons, taught by Amy, currently working through
**Poco Piano for Young People, Book 2**. He finds middle C unaided. He knows
none of the staff mnemonics.

**He currently identifies notes by reading the finger numbers printed above
them.** This is the crux of the whole design. He is not a beginner being taught
from scratch — he has a working decoding strategy that is faster, today, than
the one we want to install. Amy identified letter names and their keyboard
positions as the useful thing to practise.

Three consequences bind the design:

1. **The app must never display finger numbers.** Anywhere. They are the
   competing strategy.
2. **The answer must be a key, not a number.** Naming and locating belong in one
   action, because separate "name the note" and "find the key" drills are
   exactly the shape that fails to transfer to playing.
3. **There will be a period where he is slower and less accurate than he is
   with finger numbers.** This dip is when a child abandons a new strategy. It
   is the reason this design has no timer, no penalties, and no correctness
   streaks.

### Curriculum alignment

Book 2 masters three new notes in each hand, reaching up to Treble C and down to
Bass C — approximately **C3–C5, both clefs**, and introduces sharps and flats
without key signatures. The level ladder below terminates exactly at that range,
so the app never asks for a note Amy has not reached.

Note that the starting three notes (B3, C4, D4) sit in the gap between the
staves: in treble clef D4 is the space below the bottom line, C4 the first ledger
line below, B3 below that; in bass clef B3 is the space above the top line and C4
a ledger line above. **Ledger lines are required from day one**, not as a later
refinement — and the notes he starts with are the ones that look most ambiguous
on the page, which is precisely why finger numbers were easier.

### Goal ordering

Accuracy first, then speed; transfer expected to follow. Taken as given. The one
design lever that makes transfer likelier is coupling notation to the keyboard in
a single action, which this design does.

## Decisions

Every row below was settled in the 2026-09-12 interview.

| # | Decision | Rationale / trade-off accepted |
|---|---|---|
| D1 | **Grand staff, both clefs, always** | Matches his book; makes the clef something he reads rather than implied context. Costs vertical screen space. |
| D2 | **Answer = locate on keyboard, then name by letter; keys unlabelled** | Exactly what Amy asked for, coupled in one thought. ~2 taps per note. Keys carry no letter labels during a round, or the naming step would be free (see OQ-2). |
| D3 | **Fixed C3–C5 keyboard from level 1** | The keyboard's geometry never moves while he builds a spatial map; early levels simply have most keys inactive. No relayout when levels widen. |
| D4 | **Wrong answers: reveal, no penalty, requeue later in the round** | Repetition where it is needed without failure feeling like failure. No red X, no retry-until-right (three buttons are brute-forceable). |
| D5 | **Pitch sounds on correct answers only** | Free ear-training, strong reward at 6. Errors stay silent, consistent with the no-penalty stance. Adds a soundfont dependency; mobile-only. |
| D6 | **Level unlocks on consistency across sessions** | High accuracy in 2+ rounds on 2+ distinct days, not one lucky round. Unlocking too early is how a child gets stuck and discouraged. |
| D7 | **Next note weighted toward recently-missed notes** | Concentrates five minutes where the difficulty is. Full spaced repetition deferred until the note set is large enough to justify it. |
| D8 | **Stars for accuracy, streak for attendance** | A correctness streak would punish the strategy-switch dip. Days-practised rewards turning up, which is the behaviour we actually want. |
| D9 | **Answer input behind an interface; MIDI deferred** | Near-zero cost now, avoids a rewrite if answering on his real piano is wanted later. |
| D10 | **Single learner, offline, no accounts, no network calls** | No privacy policy, no age rating, no COPPA/GDPR-K exposure. Sideloaded APK. Revisit only if it is ever shared. |
| D11 | **Android is the only build target for now** | He practises on a Samsung A-series tablet. `ios/` stays in the repo, unbuilt — no Mac and no Apple Developer membership needed until something changes. |
| D12 | **Tablet-first, phone-supported** | Landscape-friendly responsive layout, tested down to phone portrait. |
| D13 | **Five-minute session shape** | Opens straight into a round. No menus, no tutorial, no setup, nothing to resume. A round has a visible end. |

## The level ladder

White notes only, widening outward from middle C. Terminates at Book 2's range.

| Level | Notes added | Level note set | Shape |
|---|---|---|---|
| 1 | B3, C4, D4 | B3 C4 D4 | Middle C and its two neighbours |
| 2 | A3, E4 | A3–E4 (5) | Spans the gap between the staves |
| 3 | F4, G4 | C4–G4 (5) | Right-hand C position, in the treble staff proper |
| 4 | F3, G3 | F3–C4 (5) | Left-hand C position, in the bass staff proper |
| 5 | — | F3–G4 (9) | Both hands combined |
| 6 | A4, B4, C5 | C4–C5 treble (8) | Full treble octave, reaching Treble C |
| 7 | E3, D3, C3 | C3–C4 bass (8) | Full bass octave, reaching Bass C |
| 8 | — | C3–C5 (15) | Book 2's complete white-note range |
| 9+ | Sharps and flats | — | Deferred; Book 2 introduces them without key signatures |

## Phases

1. **Renderer** — grand staff with ledger lines, one note, via `CustomPainter`
   plus Bravura (SMuFL reference font, SIL OFL). Golden tests at both
   orientations.
2. **Keyboard** — fixed C3–C5, active/inactive keys, hit-testing sized for
   6-year-old fingers, unlabelled keys (see OQ-2).
3. **Exercise loop** — level note set, weighted selection, requeue on miss,
   reveal-and-continue. No audio, no persistence yet. First build he can try.
4. **Progress** — local persistence, stars per round, attendance streak, unlock
   rule D6, the level ladder.
5. **Audio** — `flutter_midi_pro` plus a small piano soundfont, behind a
   `NotePlayer` interface with a no-op implementation so the Linux desktop build
   (used for fast iteration) still runs.
6. **Levels 2–8** — data, not code, if phases 1–4 are right.

## Acceptance

- He completes a round unaided, without finger numbers anywhere on screen.
- A missed note reliably reappears within the same round.
- Level 1 → 2 unlocks only after two high-accuracy rounds on two distinct days.
- Round fits inside five minutes with slack, from cold app start.
- Renders and is playable on the Samsung A-series tablet and on a phone in
  portrait.
- No network calls in the shipped APK.
- Amy agrees the note ladder matches what she is teaching.

## Open Questions

1. **Does C3–C5 match what he actually plays?** Taken from the publisher's
   description of Book 2, not from his music. Worth confirming with Amy before
   tuning level 8. Does not block levels 1–4.
   **Resolution:** pending.
2. **Step order, and whether keys carry letter labels.** D2 settled *locate then
   name*. But if the keys are labelled, naming after locating is free — he reads
   the answer off the key he just tapped. Two ways out: unlabelled keys, or swap
   to *name then locate*, which is the better cognitive order (identify, then
   find) and immune to the leak.
   **Resolution (2026-09-12): locate then name, keys unlabelled.** D2's ordering
   stands unchanged; the leak is closed by removing the labels rather than by
   reordering. Residual risk accepted: he can find the key by shape or position
   before committing to an identity, so a correct location does not prove he knew
   which note it was. The naming step that follows is what catches that, and
   per-step accuracy is instrumented separately (D7 weighting uses the name step)
   so the data will show if locating is running ahead of naming. Revisit if it
   does. Labels in a separate no-pressure practice mode remain available as a
   later addition, not part of v1.
3. **How is C4 notated in a given question?** It can appear as a ledger line
   below the treble staff or above the bass staff, and the two look different. He
   needs both. Recommendation: randomise per question.
   **Resolution:** pending.
4. **Round length.** 12 items ≈ 24 taps as a starting guess, tuned by watching
   him. Should be configuration, not a constant.
   **Resolution:** pending — tune with the learner.
5. **Does Amy get visibility?** A shareable progress summary would align the
   practice with her teaching, at the cost of the first feature that is not for
   him. Deferred, not rejected.
   **Resolution:** pending.

## References

- DEC-0001 — Flutter/Dart over Unity, React Native and Kotlin Multiplatform
  (`cli-decisions show DEC-0001`)
- Poco Piano for Young People, Book 2 — Ying Ying Ng & Margaret O'Sullivan
  Farrell ([Faber Music](https://www.fabermusic.com/shop/poco-piano-for-young-children-book-2-p470940))
- Bravura / SMuFL — [smufl.org](https://www.smufl.org/software/), SIL OFL
- `flutter_midi_pro` — .sf2 synthesis, FluidSynth on Android
