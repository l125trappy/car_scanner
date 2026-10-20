import 'package:flutter_test/flutter_test.dart';
import 'package:car_scanner/ocr_parser.dart';

OcrLine line(String text, double x, double y, {double width = 90, double height = 15}) {
  return OcrLine(text: text, x: x, y: y, width: width, height: height);
}

void main() {
  group('reconstructCarRows', () {
    test('keeps an already-merged full row as-is', () {
      final lines = [line('HGK-80-H 1438548 NEMST60', 68, 177, width: 300)];
      final results = reconstructCarRows(lines);

      expect(results.length, 1);
      expect(results[0].plate, 'HGK-80-H');
    });

    test('matches a plate fragment with its unit+location fragment', () {
      final lines = [
        line('JDP-17-R', 814, 230),
        line('1467265 NEAMS50', 949, 231),
      ];
      final results = reconstructCarRows(lines);

      expect(results.length, 1);
      expect(results[0].plate, 'JDP-17-R');
      expect(results[0].unit, '1467265');
      expect(results[0].location, 'NEAMS50');
    });

    test('does not match fragments on different rows', () {
      final lines = [
        line('JDP-17-R', 814, 230),
        line('1467265 NEAMS50', 949, 900),
      ];
      expect(reconstructCarRows(lines), isEmpty);
    });

    test('does not match a fragment to the left of the plate', () {
      final lines = [
        line('JDP-17-R', 814, 230),
        line('1467265 NEAMS50', 700, 230),
      ];
      expect(reconstructCarRows(lines), isEmpty);
    });

    test('picks the closest candidate when multiple are in range', () {
      final lines = [
        line('JDP-17-R', 814, 230),
        line('1000000 NEAAA11', 900, 230),
        line('2000000 NEBBB22', 1000, 230),
      ];
      final results = reconstructCarRows(lines);

      expect(results.length, 1);
      expect(results[0].unit, '1000000');
    });

    test('matches two independent split rows without cross-matching', () {
      final lines = [
        line('JDP-17-R', 814, 230),
        line('1467265 NEAMS50', 949, 231),
        line('JDP-18-R', 814, 256),
        line('1467224 NEAMS50', 949, 255),
      ];
      final results = reconstructCarRows(lines);

      expect(results.length, 2);
      final row17 = results.firstWhere((r) => r.plate == 'JDP-17-R');
      expect(row17.unit, '1467265');
      final row18 = results.firstWhere((r) => r.plate == 'JDP-18-R');
      expect(row18.unit, '1467224');
    });

    test('returns empty list for empty input', () {
      expect(reconstructCarRows([]), isEmpty);
    });
  });
}