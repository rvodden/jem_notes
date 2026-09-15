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

**Each clone must run `git config core.hooksPath .husky` once.** `ai-sdlc init`
picks `.husky/pre-push` whenever a repo has no `package.json`, but git reads
`.git/hooks/` by default and husky is a Node tool this Flutter project will never
install — so without that config the hook never fires and CI is the only gate.

**WSL note:** the Flutter SDK on `PATH` may be a *Windows* install under
`/mnt/c/`. Its scripts have CRLF line endings and cannot run from WSL
(`/usr/bin/env: 'bash\r': No such file or directory`). A Linux SDK inside WSL is
required to build from this shell.

## RFCs and backlog tasks

RFCs live in **`spec/rfcs/`**, pinned by `.ai-sdlc/adopter-authoring.yaml`. This
is not cosmetic: `cli-rfc init` defaults to `rfcs/`, but the Definition-of-Ready
gate's reference resolver looks for RFC IDs **only** under `spec/rfcs/` and
hard-fails any task citing one otherwise. The pin makes both tools agree; without
it the next `rfc init` recreates `rfcs/` and the index silently prefers it,
splitting RFCs across two directories.

Filenames must start with `RFC-NNNN-` or `cli-rfc index` ignores them.

Backlog tasks are `backlog/tasks/<id-lower> - <slug>.md` — note the space before
the hyphen, which `/ai-sdlc execute` globs on. Before committing a new task run:

```bash
cli-dor-check --task "backlog/tasks/<file>.md"   # silence means clean
cli-backlog-verify                                # duplicate-id check
```

## Platforms

**Android is the shipping target** (DEC-0002). The learner practises on a
Samsung A-series tablet, the app is sideloaded, and there is no intent to
publish — so `ios/` stays in the repo unbuilt, and no Mac or Apple Developer
membership is needed.

**`web/` is a review-only target** (DEC-0006). It exists so a playable build can
be handed to a reviewer who is not at the machine:

```bash
flutter build web --release --no-web-resources-cdn --pwa-strategy=none
```

`--no-web-resources-cdn` bundles CanvasKit locally instead of fetching it from
a Google CDN, which is what makes the build work under a strict
content-security policy — and keeps it consistent with D10's no-network stance.

It earned its place immediately: playing the web build is what revealed that the
letter buttons could be answered by position rather than by reading. Two things
it cannot tell you, both of which need the real tablet — whether a six-year-old's
finger catches the black keys, and whether the reveal pause feels right. And once
audio lands (phase 5), `flutter_midi_pro` is mobile-only, so **the web build will
be silent**.

Never treat a green web build as evidence the app works. It has no test coverage
of its own and nobody ships to it.

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

`main` is protected: required check `ai-sdlc/pr-ready`, strict (branch must be up
to date), no force pushes, no deletions. All work goes through a PR.
**Never merge PRs — only humans merge.**

**No approving review is required (GOV-1 / DEC-0003).** With one human
maintainer that rule was unsatisfiable — GitHub forbids approving your own PR,
so it could only ever be met by admin bypass, and both early merges did exactly
that. The review gate is therefore the merge button: a human reads the PR and
clicks. To keep that click meaningful, auto-merge is off in two places — the
repo setting "Allow auto-merge", and the `auto-enable-auto-merge.yml` workflow
itself, set to `disabled_manually` via the Actions API. Both must be turned back
on to restore hands-off merging, which is a decision to make together with
giving agents a separate identity.

A file-level `if: vars.AI_SDLC_AUTO_MERGE == 'true'` guard on that workflow
would be tidier than a manual disable, but the `gh` token lacks the `workflow`
scope, so `.github/workflows/**` cannot be written via the API (404). Run
`gh auth refresh -s workflow` on the machine to unblock that.

### The review check certifies nothing

Repo variable `AISDLC_REVIEW_STUB_AUTOPASS=true` is set (DEC-0004), so
`ai-sdlc-review.yml`'s `Post Review Results` check reports success **without any
review running in CI**. It shipped as a stub that failed closed, and since it was
never a required check its red status blocked nothing — it only made every PR read
UNSTABLE, which trains you to ignore check colour.

Review actually happens in two places: the maintainer reading the PR before
clicking merge (DEC-0003), and the reviewer subagents of `/ai-sdlc execute`,
which run locally and write DSSE verdicts to `.ai-sdlc/verdicts/`.

**If CI-side review is ever wired up, unset this variable in the same change** —
otherwise the stub's success masks the real result.

### Commit signing

Commits are signed via 1Password (`gpg.format ssh`, `commit.gpgsign true`,
`gpg.ssh.program` → `op-ssh-sign-wsl.exe`). When 1Password is unreachable —
notably when the operator is remote from the machine — `git commit` fails with
`1Password: failed to fill whole buffer` and SSH push fails with
`communication with agent failed`. Two things follow:

- The GitHub contents API is the fallback for landing work, but **API commits
  are not signed**. `main` already carries two such commits (`8929016`,
  `b3f769a`).
- Only a **squash** merge replaces branch commits with a single GitHub-signed
  commit. A merge commit *preserves* the originals, unsigned and all.

`required_signatures` is deliberately **off**: enabling it would reject exactly
those fallback commits and block all work whenever 1Password is away.
