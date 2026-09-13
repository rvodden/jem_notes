import 'package:flutter_test/flutter_test.dart';
import 'package:jem_notes/jem_notes.dart';

void main() {
  // One staff space = 10px keeps the expected values readable: a diatonic step
  // is 5px, a staff is 40px tall.
  const StaffGeometry geometry = StaffGeometry(staffSpace: 10);

  const Pitch b3 = Pitch(NoteLetter.b, 3);
  const Pitch c4 = Pitch.middleC;
  const Pitch d4 = Pitch(NoteLetter.d, 4);

  group('pitch', () {
    test('parses scientific notation, case-insensitively', () {
      expect(Pitch.parse('C4'), c4);
      expect(Pitch.parse('b3'), b3);
      expect(Pitch.parse(' D4 '), d4);
    });

    test('rejects nonsense rather than guessing', () {
      expect(() => Pitch.parse('H4'), throwsArgumentError);
      expect(() => Pitch.parse('C'), throwsArgumentError);
      expect(() => Pitch.parse('C#4'), throwsArgumentError);
    });

    test('counts diatonic steps, so B to C is one step like any other', () {
      expect(c4.diatonicStep - b3.diatonicStep, 1);
      expect(d4.diatonicStep - c4.diatonicStep, 1);
    });

    test('range is ascending and inclusive', () {
      final List<Pitch> range = Pitch.range(b3, d4);
      expect(range, <Pitch>[b3, c4, d4]);
      expect(
        Pitch.range(
          const Pitch(NoteLetter.c, 3),
          const Pitch(NoteLetter.c, 5),
        ).length,
        15,
      );
    });
  });

  group('staff layout', () {
    test('treble staff sits above the bass staff with a four-space gap', () {
      expect(geometry.trebleTopY, 0);
      expect(geometry.trebleBottomY, 40);
      expect(geometry.bassTopY, 80);
      expect(geometry.bassBottomY, 120);
      expect(geometry.height, 120);
    });

    test('each staff has five evenly spaced lines', () {
      expect(geometry.lineYsOf(Clef.treble), <double>[0, 10, 20, 30, 40]);
      expect(geometry.lineYsOf(Clef.bass), <double>[80, 90, 100, 110, 120]);
    });

    test('clef anchor pitches land on their naming lines', () {
      // Treble G is the second line up; bass F is the fourth line up.
      expect(geometry.yForPitch(Clef.treble.anchorPitch, Clef.treble), 30);
      expect(geometry.yForPitch(Clef.bass.anchorPitch, Clef.bass), 90);
    });

    test('top line pitches are four spaces above the bottom line', () {
      expect(Clef.treble.topLinePitch, Pitch.parse('F5'));
      expect(Clef.bass.topLinePitch, Pitch.parse('A3'));
    });
  });

  group('the level-1 notes', () {
    test('C4 in treble is one space below the bottom line', () {
      expect(geometry.yForPitch(c4, Clef.treble), 50);
      expect(geometry.ledgerLineYsFor(c4, Clef.treble), <double>[50]);
    });

    test('C4 in bass is one space above the top line', () {
      expect(geometry.yForPitch(c4, Clef.bass), 70);
      expect(geometry.ledgerLineYsFor(c4, Clef.bass), <double>[70]);
    });

    test('C4 is written higher in treble than in bass', () {
      // The two notations are different heights for the same sound — which is
      // exactly why the exercise varies them (RFC-0001 OQ-3).
      // Smaller y is higher on the canvas.
      expect(
        geometry.yForPitch(c4, Clef.treble),
        lessThan(geometry.yForPitch(c4, Clef.bass)),
      );
    });

    test('D4 in treble sits in the space below the staff, no ledger line', () {
      expect(geometry.yForPitch(d4, Clef.treble), 45);
      expect(geometry.ledgerLineYsFor(d4, Clef.treble), isEmpty);
    });

    test('B3 in bass sits in the space above the staff, no ledger line', () {
      expect(geometry.yForPitch(b3, Clef.bass), 75);
      expect(geometry.ledgerLineYsFor(b3, Clef.bass), isEmpty);
    });
  });

  group('ledger lines', () {
    test('notes on or within the staff need none', () {
      for (final Pitch pitch in Pitch.range(
        Pitch.parse('E4'),
        Pitch.parse('F5'),
      )) {
        expect(
          geometry.ledgerLineYsFor(pitch, Clef.treble),
          isEmpty,
          reason: '${pitch.scientificName} is inside the treble staff',
        );
      }
    });

    test('accumulate one per line position, nearest the staff first', () {
      // A3 is three ledger lines below the treble staff: C4, A3 on lines, with
      // B3 in the space between.
      expect(geometry.ledgerLineYsFor(Pitch.parse('A3'), Clef.treble), <double>[
        50,
        60,
      ]);
      // Above the treble staff: F5 top line, G5 space, A5 ledger, B5 space,
      // C6 ledger — so C6 takes two, not three.
      expect(geometry.ledgerLineYsFor(Pitch.parse('C6'), Clef.treble), <double>[
        -10,
        -20,
      ]);
    });
  });

  group('default clef', () {
    test('middle C and above read treble, below it bass', () {
      expect(StaffGeometry.defaultClefFor(c4), Clef.treble);
      expect(StaffGeometry.defaultClefFor(b3), Clef.bass);
      expect(StaffGeometry.defaultClefFor(Pitch.parse('C3')), Clef.bass);
      expect(StaffGeometry.defaultClefFor(Pitch.parse('C5')), Clef.treble);
    });

    test(
      'every pitch in C3-C5 has a distinct, monotonically rising position',
      () {
        final List<Pitch> ladder = Pitch.range(
          Pitch.parse('C3'),
          Pitch.parse('C5'),
        );
        final List<double> ys = ladder
            .map(
              (Pitch p) =>
                  geometry.yForPitch(p, StaffGeometry.defaultClefFor(p)),
            )
            .toList();

        expect(
          ys.toSet().length,
          ladder.length,
          reason: 'positions must be distinct',
        );
        for (int i = 1; i < ys.length; i++) {
          expect(
            ys[i],
            lessThan(ys[i - 1]),
            reason: '${ladder[i]} must sit above ${ladder[i - 1]}',
          );
        }
      },
    );
  });
  group('letter casing', () {
    test('the model is canonical, the child-facing label is lower case', () {
      expect(NoteLetter.c.label, 'C');
      expect(NoteLetter.c.displayLabel, 'c');
      expect(Pitch.middleC.scientificName, 'C4');
      for (final NoteLetter letter in NoteLetter.values) {
        expect(letter.displayLabel, letter.label.toLowerCase());
      }
    });
  });
}
