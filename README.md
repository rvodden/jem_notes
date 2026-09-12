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

## Local toolchain (WSL)

Both SDKs must be **Linux** builds. A Windows Flutter SDK under `/mnt/c` has
CRLF shebangs (`/usr/bin/env: 'bash\r': No such file or directory`), and a
Windows Android SDK ships win32 binaries (`adb.exe`, `aapt2.exe`) that the Linux
toolchain cannot execute. Installed versions here: Flutter 3.47.4 / Dart 3.13.3,
Android SDK 36.0.0 (`compileSdk = 36`, matching this Flutter release's default).

```bash
# Flutter
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git ~/flutter
export PATH="$HOME/flutter/bin:$PATH"

# Linux desktop target (fast local iteration via WSLg)
sudo apt-get install -y clang libgtk-3-dev pkg-config ninja-build libstdc++-12-dev

# Android SDK — command-line tools only, no Android Studio needed.
# The zip MUST end up at $ANDROID_HOME/cmdline-tools/latest/ or sdkmanager
# cannot resolve its own package path.
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
sdkmanager --install platform-tools "platforms;android-36" "build-tools;36.0.0"
flutter config --android-sdk "$ANDROID_HOME"
flutter doctor --android-licenses
```

Two harmless warnings on the way through: `sdkmanager` reports itself deprecated
in favour of the newer `android` CLI, and the Gradle run warns that it
"only understands SDK XML versions up to 3" — both cosmetic.

Verified working: `flutter build apk --debug` and `flutter build linux --debug`
both succeed, and the Linux bundle launches under WSLg. Only the Chrome/web
target is absent, and web is not a platform of this project.

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
