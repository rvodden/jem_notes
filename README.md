# Jem Notes

A mobile app (Android + iOS) that helps a child learn to read music.

**First use case:** show a single note on a staff; the child identifies (a) its
letter name and (b) its position on a piano keyboard.

## Stack

Flutter / Dart — chosen over Unity, React Native + Expo and Kotlin
Multiplatform. The full rationale, the options considered and the
counter-argument are recorded as **DEC-0001**:

```bash
cli-decisions show DEC-0001
```

## Getting started

Requires a **Linux** Flutter SDK when working inside WSL — a Windows SDK under
`/mnt/c` has CRLF shebangs and cannot execute from a Linux shell.

```bash
flutter pub get
flutter test          # widget + unit tests
flutter analyze       # static analysis
dart format .         # formatting
flutter run           # needs a connected device or desktop toolchain
```

## Verification

`flutter analyze`, `dart format --set-exit-if-changed` and
`flutter test --coverage` are the gate — run locally by `.husky/pre-push` and in
CI by `.github/workflows/ai-sdlc-gate.yml`, which rolls them up into the single
required `ai-sdlc/pr-ready` status check.

`ai-sdlc init` wrote the hook to `.husky/pre-push`, but git only reads that
directory when told to — and husky itself is a Node tool this project has no use
for. So each clone needs, once:

```bash
git config core.hooksPath .husky
```

Without it the hook is inert and CI is your only gate.

See `CLAUDE.md` for the pre-commit checklist and project governance.
