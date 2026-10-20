import 'package:flutter_test/flutter_test.dart';
import 'package:car_scanner/ocr_parser.dart';

void main() {
  group('extractPlateSubstring', () {
    test('extracts the plate from real-world noisy detection', () {
      final result = extractPlateSubstring('NL KFR-82-D HEDIN AUTOMOTIVEN');
      expect(result, 'KFR-82-D');
    });

    test('extracts a plate with a single-letter segment', () {
      final result = extractPlateSubstring('NL V-05-LJF SOME DEALER TEXT');
      expect(result, 'V-05-LJF');
    });

    test('returns null when no plate-shaped text is present', () {
      final result = extractPlateSubstring('NL HEDIN AUTOMOTIVE');
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      expect(extractPlateSubstring(''), isNull);
    });

    test('handles lowercase input', () {
      final result = extractPlateSubstring('nl kfr-82-d hedin automotive');
      expect(result, 'KFR-82-D');
    });
  });
}