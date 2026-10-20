import 'package:flutter_test/flutter_test.dart';
import 'package:car_scanner/ocr_parser.dart';

OcrLine line(String text, double x, double y, {double width = 90, double height = 15}) {
  return OcrLine(text: text, x: x, y: y, width: width, height: height);
}

void main() {
  group('rowToCarRow', () {
    test('converts a 3-fragment row into a CarRow', () {
      final row = [
        line('JDP-15-R', 973, 293),
        line('1467281', 1110, 295),
        line('NEAMS50', 1207, 295),
      ];

      final result = rowToCarRow(row);

      expect(result, isNotNull);
      expect(result!.plate, 'JDP-15-R');
      expect(result.unit, '1467281');
      expect(result.location, 'NEAMS50');
    });

    test('converts an already-merged single-line row', () {
      final row = [line('HGK-80-H 1438548 NEMST60', 68, 177, width: 300)];

      final result = rowToCarRow(row);

      expect(result, isNotNull);
      expect(result!.plate, 'HGK-80-H');
      expect(result.unit, '1438548');
      expect(result.location, 'NEMST60');
    });

    test('returns null for a row that is just a plate fragment', () {
      final row = [line('HKF-62-B', 68, 354)];

      final result = rowToCarRow(row);

      expect(result, isNull);
    });

    test('returns null for an empty row', () {
      final result = rowToCarRow([]);
      expect(result, isNull);
    });
  });

  group('isHeaderRow', () {
    test('identifies a model name as a header', () {
      final row = [line('BMW X1', 67, 513, width: 74)];
      final parsed = rowToCarRow(row);

      expect(isHeaderRow(row, parsed), isTrue);
    });

    test('identifies a multi-word model name as a header', () {
      final row = [line('ALFA ROMEO JUNIOR', 65, 148, width: 216)];
      final parsed = rowToCarRow(row);

      expect(isHeaderRow(row, parsed), isTrue);
    });

    test('does not flag a full data row as a header', () {
      final row = [line('HGK-80-H 1438548 NEMST60', 68, 177, width: 300)];
      final parsed = rowToCarRow(row);

      expect(isHeaderRow(row, parsed), isFalse);
    });

    test('does not flag a multi-fragment partial row as a header', () {
      final row = [
        line('JDP-15-R', 973, 293),
        line('1467281', 1110, 295),
        line('NEAMS50', 1207, 295),
      ];
      final parsed = rowToCarRow(row);

      expect(isHeaderRow(row, parsed), isFalse);
    });

    test('does not flag the "type/kent." column label as a header', () {
      final row = [line('type/kent.', 67, 116, width: 89)];
      final parsed = rowToCarRow(row);

      expect(isHeaderRow(row, parsed), isFalse);
    });

    test('does not flag the "unit" column label as a header', () {
      final row = [line('unit', 229, 119, width: 36)];
      final parsed = rowToCarRow(row);

      expect(isHeaderRow(row, parsed), isFalse);
    });

    test('does not flag "laatste" or "lokatie" as headers', () {
      final row1 = [line('laatste', 331, 94, width: 62)];
      final row2 = [line('lokatie', 331, 118, width: 62)];

      expect(isHeaderRow(row1, rowToCarRow(row1)), isFalse);
      expect(isHeaderRow(row2, rowToCarRow(row2)), isFalse);
    });
  });
}