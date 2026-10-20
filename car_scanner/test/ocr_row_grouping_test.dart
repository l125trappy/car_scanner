import 'package:flutter_test/flutter_test.dart';
import 'package:car_scanner/ocr_parser.dart';

OcrLine line(String text, double x, double y, {double width = 90, double height = 15}) {
  return OcrLine(text: text, x: x, y: y, width: width, height: height);
}

void main() {
  group('groupLinesIntoRows', () {
    test('groups three fragments on the same row together', () {
      final lines = [
        line('JDP-15-R', 973, 293),
        line('1467281', 1110, 295),
        line('NEAMS50', 1207, 295),
      ];

      final rows = groupLinesIntoRows(lines);

      expect(rows.length, 1);
      expect(rows[0].length, 3);
    });

    test('separates two distinct rows', () {
      final lines = [
        line('HGK-80-H 1438548 NEMST60', 68, 177, width: 300),
        line('HLG-47-F', 68, 203),
      ];

      final rows = groupLinesIntoRows(lines);

      expect(rows.length, 2);
    });

    test('orders lines left-to-right within a row', () {
      final lines = [
        line('NEAMS50', 1207, 295),
        line('JDP-15-R', 973, 293),
        line('1467281', 1110, 295),
      ];

      final rows = groupLinesIntoRows(lines);

      expect(rows[0][0].text, 'JDP-15-R');
      expect(rows[0][1].text, '1467281');
      expect(rows[0][2].text, 'NEAMS50');
    });

    test('returns empty list for empty input', () {
      final rows = groupLinesIntoRows([]);
      expect(rows, isEmpty);
    });

    test('handles a single line', () {
      final rows = groupLinesIntoRows([line('BMW X1', 67, 513)]);
      expect(rows.length, 1);
      expect(rows[0].length, 1);
    });
  });
}