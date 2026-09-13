---
id: JEM-4
title: Local progress - stars per round, attendance streak, level unlocking
status: To Do
priority: medium
references:
  - spec/rfcs/RFC-0001-note-reading-app-design.md
dependencies:
  - JEM-3
labels:
  - progress
---

## Context

RFC-0001 phase 4. Makes progress persist and puts the level ladder behind an
unlock rule.

Two design points from RFC-0001 that are easy to get backwards:

- **D8 — stars measure accuracy within a round; the streak measures attendance,
  not correctness.** A correctness streak would punish exactly the period when he
  is slower with letter names than with finger numbers, which is when a child
  abandons a new strategy.
- **D6 — a level unlocks on consistency across sessions**, not one good round: high
  accuracy in two or more rounds on two or more distinct days. A 6-year-old can
  fluke a short round, and unlocking too early is how he ends up stuck.

D10: single learner, offline, no accounts, no network calls.

## Scope

Local persistence of per-pitch attempt history, completed rounds with their
first-time-correct counts, distinct practice dates, and unlocked levels. Stars
awarded per round. Streak computed from distinct consecutive practice dates.
Unlock evaluation per D6. The level ladder from RFC-0001 encoded as data, with
levels 2–8 defined but locked.

**Out of scope:** any network call, accounts, profiles, a parent or teacher view,
audio, cloud sync.

## Acceptance criteria

- [ ] Progress survives app restart and is stored on-device only
- [ ] A completed round awards 3 stars at 100% first-time-correct, 2 at 90% or
      above, 1 otherwise
- [ ] Streak counts consecutive distinct dates with at least one completed round;
      two rounds on the same day count once
- [ ] A gap of one or more days resets the streak to 1 on the next round
- [ ] Level 2 stays locked after a single high-accuracy round, and after two
      high-accuracy rounds on the *same* day
- [ ] Level 2 unlocks after two high-accuracy rounds on two distinct days
- [ ] Levels 2–8 exist as data matching RFC-0001's ladder, and levels above the
      highest unlocked one are not selectable
- [ ] Per-pitch history persists and feeds JEM-3's miss weighting across rounds,
      not just within one
- [ ] A test asserts the shipped app makes no network calls
- [ ] `flutter analyze` and `dart format --set-exit-if-changed` clean;
      `flutter test --coverage` passes

## Done state

`flutter test` includes tests for each star threshold, for streak continuation,
same-day collapse and gap reset, and for all three unlock cases (one round, two
same-day, two distinct-day). Progress verified to survive a restart on the tablet.
