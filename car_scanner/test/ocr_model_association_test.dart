import 'package:flutter_test/flutter_test.dart';
import 'package:car_scanner/ocr_parser.dart';

OcrLine line(String text, double x, double y, {double width = 90, double height = 15}) {
  return OcrLine(text: text, x: x, y: y, width: width, height: height);
}

void main() {
  group('parseOcrLines', () {
    test('attaches a single-word model to a merged full row below it', () {
      final lines = [
        line('BMW X1', 67, 513, width: 74),
        line('JLS-72-Z 1474410 NEAMS50', 68, 541, width: 300),
      ];

      final result = parseOcrLines(lines);

      expect(result.length, 1);
      expect(result[0].model, 'BMW X1');
      expect(result[0].carRow.plate, 'JLS-72-Z');
    });

    test('attaches a multi-word model to multiple rows below it', () {
      final lines = [
        line('ALFA ROMEO JUNIOR', 65, 148, width: 216),
        line('HGK-80-H 1438548 NEMST60', 68, 177, width: 300),
        line('HLG-47-F', 68, 203),
        line('1449990 NEAMS50', 203, 204, width: 174),
      ];

      final result = parseOcrLines(lines);

      expect(result.length, 2);
      for (final entry in result) {
        expect(entry.model, 'ALFA ROMEO JUNIOR');
      }
    });

    test('switches to a new model after a new header appears', () {
      final lines = [
        line('BMW X1', 67, 513, width: 74),
        line('JLS-72-Z 1474410 NEAMS50', 68, 541, width: 300),
        line('BMW X3', 68, 593, width: 73),
        line('JLS-49-T 1474352 NEAMF60', 68, 624, width: 300),
      ];

      final result = parseOcrLines(lines);

      expect(result.length, 2);
      final x1row = result.firstWhere((e) => e.carRow.plate == 'JLS-72-Z');
      final x3row = result.firstWhere((e) => e.carRow.plate == 'JLS-49-T');
      expect(x1row.model, 'BMW X1');
      expect(x3row.model, 'BMW X3');
    });

    test('does not cross-attach a header from a different column', () {
      final lines = [
        // column 1 header
        line('BMW X1', 67, 513, width: 74),
        // column 2 header (different x), positioned above column 1's row
        line('HYUNDAI BAYON', 450, 152, width: 164),
        // column 1 data row, should still get BMW X1, not HYUNDAI BAYON
        line('JLS-72-Z 1474410 NEAMS50', 68, 541, width: 300),
      ];

      final result = parseOcrLines(lines);

      expect(result.length, 1);
      expect(result[0].model, 'BMW X1');
    });

    test('ignores known column labels entirely', () {
      final lines = [
        line('type/kent.', 67, 116, width: 89),
        line('unit', 229, 119, width: 36),
        line('laatste', 331, 94, width: 62),
        line('lokatie', 331, 118, width: 62),
        line('BMW X1', 67, 513, width: 74),
        line('JLS-72-Z 1474410 NEAMS50', 68, 541, width: 300),
      ];

      final result = parseOcrLines(lines);

      expect(result.length, 1);
      expect(result[0].model, 'BMW X1');
    });

    test('handles a row with no header above it (null model)', () {
      final lines = [
        line('JLS-72-Z 1474410 NEAMS50', 68, 541, width: 300),
      ];

      final result = parseOcrLines(lines);

      expect(result.length, 1);
      expect(result[0].model, isNull);
    });

    test('correctly reconstructs and attaches model for a split row', () {
      final lines = [
        line('HYUNDAI TUCSCA', 973, 270, width: 179),
        line('JDP-17-R', 814, 230),
        line('1467265 NEAMS50', 949, 231, width: 174),
      ];

      final result = parseOcrLines(lines);

      expect(result.length, 1);
      expect(result[0].carRow.plate, 'JDP-17-R');
      expect(result[0].carRow.unit, '1467265');
    });

    test('returns empty list for empty input', () {
      expect(parseOcrLines([]), isEmpty);
    });

    test('does not treat a malformed dashed plate fragment as a header', () {
    final lines = [
      line('FORD FOCUS SW', 68, 1527, width: 142),
      line('GDN-65-', 68, 1695, width: 80), // malformed/truncated plate fragment
      line('GDR-65-R 1411644 NEAMS50', 68, 1797, width: 309),
      line('GDT-42-B 1411594 NEZEE60', 68, 1825, width: 309),
    ];

    final result = parseOcrLines(lines);

    for (final entry in result) {
      expect(entry.model, 'FORD FOCUS SW');
    }
  });
  });
}