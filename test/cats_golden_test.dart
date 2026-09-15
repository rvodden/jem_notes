import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';

Widget _sheet(Widget child) => MaterialApp(
  theme: ThemeData(brightness: Brightness.light),
  home: Scaffold(
    backgroundColor: Colors.white,
    body: Center(child: child),
  ),
);

Future<void> _pump(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_sheet(child));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('golden: every cat in the catalogue', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const Size(760, 340),
      SizedBox(
        width: 720,
        child: Wrap(
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final CatReward reward in CatCatalogue.all)
              CatView(cat: reward.cat, size: 96),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(Wrap),
      matchesGoldenFile('goldens/cats-catalogue.png'),
    );
  });

  testWidgets('golden: moods, and a cat not yet met', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const Size(560, 180),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final CatMood mood in CatMood.values)
            CatView(cat: CatCatalogue.all.first.cat, mood: mood, size: 120),
          CatView(cat: CatCatalogue.all.first.cat, size: 120, faded: true),
        ],
      ),
    );
    await expectLater(
      find.byType(Row).first,
      matchesGoldenFile('goldens/cats-moods.png'),
    );
  });

  testWidgets('golden: paw prints, earned and not', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const Size(260, 120),
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PawPrint(filled: true, size: 64),
          PawPrint(filled: true, size: 64),
          PawPrint(filled: false, size: 64),
        ],
      ),
    );
    await expectLater(
      find.byType(Row).first,
      matchesGoldenFile('goldens/paw-prints.png'),
    );
  });
}
