import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test harness setup applied to every test file in this package.
///
/// Two jobs:
///
/// 1. **Load Bravura.** Widget tests get a font-less environment by default, so
///    without this every notehead and clef renders as a blank box and the
///    goldens would prove nothing.
/// 2. **Allow a little pixel drift.** Golden comparison is exact by default,
///    which makes goldens fail on a Flutter upgrade that only changed
///    anti-aliasing. Since CI tracks the stable channel rather than a pinned
///    version, exact matching would turn every Flutter release into a red
///    build. A small tolerance keeps goldens meaningful — a mispositioned note
///    moves far more than 0.5% of pixels — without that fragility.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final FontLoader loader = FontLoader('Bravura')
    ..addFont(
      File('assets/fonts/Bravura.otf').readAsBytes().then(
        (List<int> bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
      ),
    );
  await loader.load();

  // Inherit the framework's base directory rather than inventing one:
  // LocalFileComparator derives basedir from a *test file* URI, so handing it a
  // bare 'test/' silently resolves golden paths against the repo root instead.
  final LocalFileComparator existing =
      goldenFileComparator as LocalFileComparator;
  goldenFileComparator = _TolerantGoldenComparator(
    existing.basedir.resolve('flutter_test_config.dart'),
    tolerancePercent: 0.5,
  );

  await testMain();
}

class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile, {required this.tolerancePercent});

  /// Maximum share of differing pixels, as a percentage, still considered equal.
  final double tolerancePercent;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) return true;
    if (result.diffPercent * 100 <= tolerancePercent) {
      // Close enough to be the same rendering; report it so a slow drift
      // upward is still visible in test output rather than silent.
      // ignore: avoid_print
      print(
        'Golden $golden differs by '
        '${(result.diffPercent * 100).toStringAsFixed(3)}% — within the '
        '$tolerancePercent% tolerance, treating as a pass.',
      );
      return true;
    }
    await generateFailureOutput(result, golden, basedir);
    return false;
  }
}
