import 'package:flutter_test/flutter_test.dart';
import 'package:car_scanner/ocr_parser.dart';

OcrLine line(String text, {double height = 40, double width = 60}) {
  return OcrLine(text: text, x: 0, y: 0, width: width, height: height);
}

void main() {
  group('extractPlateTextFiltered', () {
    test('keeps large plate text and discards small company text', () {
      final lines = [
        line('HGK80H', height: 60),
        line('Van Dijk Autoverhuur', height: 15),
      ];

      final result = extractPlateTextFiltered(lines);

      expect(result, contains('HGK80H'));
      expect(result, isNot(contains('Van Dijk')));
    });

    test('discards the NL country band fragment', () {
      final lines = [
        line('HGK80H', height: 60),
        line('NL', height: 55),
      ];

      final result = extractPlateTextFiltered(lines);

      expect(result, contains('HGK80H'));
      expect(result, isNot(contains('NL')));
    });

    test('keeps multiple plate-height fragments together', () {
      final lines = [
        line('HGK', height: 58),
        line('80', height: 60),
        line('H', height: 59),
      ];

      final result = extractPlateTextFiltered(lines);

      expect(result, contains('HGK'));
      expect(result, contains('80'));
      expect(result, contains('H'));
    });

    test('discards short noise fragments even if tall', () {
      final lines = [
        line('HGK80H', height: 60),
        line('.', height: 58),
      ];

      final result = extractPlateTextFiltered(lines);

      expect(result, contains('HGK80H'));
      expect(result, isNot(contains('.')));
    });

    test('returns empty string for empty input', () {
      expect(extractPlateTextFiltered([]), '');
    });

    test('handles a single valid line', () {
      final result = extractPlateTextFiltered([line('HGK80H', height: 50)]);
      expect(result, 'HGK80H');
    });
  });
}