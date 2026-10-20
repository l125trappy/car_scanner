import 'package:flutter_test/flutter_test.dart';
import 'package:car_scanner/ocr_parser.dart';

void main() {
  group('tryParseFullRow', () {
    test('parses a standard complete row', () {
      final result = tryParseFullRow('HGK-80-H 1438548 NEMST60');

      expect(result, isNotNull);
      expect(result!.plate, 'HGK-80-H');
      expect(result.unit, '1438548');
      expect(result.location, 'NEMST60');
    });

    test('parses a row with a short plate segment (single letter)', () {
      final result = tryParseFullRow('V-05-LJF 1434042 NETIB61');

      expect(result, isNotNull);
      expect(result!.plate, 'V-05-LJF');
      expect(result.unit, '1434042');
      expect(result.location, 'NETIB61');
    });

    test('removes stray space inside the location code', () {
      final result = tryParseFullRow('GDB-44-T 1411354 NEBRE 60');

      expect(result, isNotNull);
      expect(result!.location, 'NEBRE60');
    });

    test('handles lowercase OCR misreads by uppercasing', () {
      final result = tryParseFullRow('jdp-15-r 1467281 neams50');

      expect(result, isNotNull);
      expect(result!.plate, 'JDP-15-R');
      expect(result.location, 'NEAMS50');
    });

    test('returns null for a plate-only line', () {
      final result = tryParseFullRow('HKF-62-B');
      expect(result, isNull);
    });

    test('returns null for a unit+location-only line', () {
      final result = tryParseFullRow('1449990 NEAMS50');
      expect(result, isNull);
    });

    test('returns null for a model header line', () {
      final result = tryParseFullRow('BMW X1');
      expect(result, isNull);
    });

    test('returns null for an empty string', () {
      final result = tryParseFullRow('');
      expect(result, isNull);
    });
  });
}