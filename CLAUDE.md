# Project instructions

## What this project is

A mobile app (Android + iOS) that helps a child learn to read music. The first
use case: show a single note on a staff; the child identifies (a) its letter
name and (b) its position on a piano keyboard.

## Toolchain — Flutter / Dart

Framework choice is recorded as **DEC-0001** in `.ai-sdlc/_decisions/events.jsonl`
(`cli-decisions show DEC-0001` for the full rationale, options considered, and
the counter-argument). Flutter was selected over Unity, React Native + Expo, and
Kotlin Multiplatform. Do not re-litigate it without reading that record.

Expected dependency shape for use case 1:

| Need | Dependency |
|---|---|
| Staff, note glyphs, ledger lines | `CustomPainter` + Bravura (SMuFL reference font, SIL OFL) |
| Piano keyboard + tap hit-testing | `CustomPainter` + `GestureDetector` |
| Note playback | `flutter_midi_pro` (.sf2 soundfont; FluidSynth on Android, AVFoundation on iOS) |
| Gamification, if it grows | `Flame` |

## Pre-commit checklist

Before EVERY commit, run these and fix any failures:

1. `flutter analyze` — static analysis
2. `dart format --output=none --set-exit-if-changed .` — formatting check
   (run `dart format .` to fix)
3. `flutter test` — all tests must pass
4. `flutter test --coverage` — before pushing; CI enforces coverage

`.husky/pre-push` runs analyse + format + coverage as the canonical local
verification gate. It no-ops until `pubspec.yaml` exists, and warns rather than
blocks when `flutter` is not on PATH.

**WSL note:** the Flutter SDK on `PATH` may be a *Windows* install under
`/mnt/c/`. Its scripts have CRLF line endings and cannot run from WSL
(`/usr/bin/env: 'bash\r': No such file or directory`). A Linux SDK inside WSL is
required to build from this shell.

## AI-SDLC quality gate

This repo is bootstrapped with the AI-SDLC framework. The single PR-ready merge
gate is `ai-sdlc/pr-ready` (see `.github/workflows/ai-sdlc-gate.yml`), which
aggregates Detect Changes + Analyse & Format + Test & Coverage. The two Flutter
jobs skip until `pubspec.yaml` exists at the repo root, and are listed in the
rollup's `allowed-skips` so the gate stays honest either way.

Run `ai-sdlc health` to verify local config and `ai-sdlc doctor` for attestation
governance state.

**Deferred: Codecov.** `ai-sdlc init` scaffolded `codecov/patch` as a second
required status check, but Codecov is not wired up, so it could never report and
blocked every PR. It has been removed from both
`.ai-sdlc/branch-protection-body.json` and the live branch-protection rule. When
Codecov is set up, add it back to that file and re-run
`ai-sdlc init --add branch-protection`. `flutter test --coverage` already
produces `coverage/lcov.info`, uploaded as a CI artifact, so the data is ready.

`main` is protected: 1 approving review, no force pushes, no deletions. All work
goes through a PR. **Never merge PRs — only humans merge.**
