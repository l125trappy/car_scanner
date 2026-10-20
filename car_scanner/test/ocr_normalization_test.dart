import 'package:flutter_test/flutter_test.dart';
import 'package:car_scanner/ocr_parser.dart';
import 'package:car_scanner/known_models.dart';

void main() {
  group('findClosestModel digit guard', () {
    test('does not match BMW I4 to BMW X1', () {
      final result = findClosestModel('BMW I4', knownModels);
      expect(result, 'BMW I4');
    });

    test('does not match BMW X1 to BMW X3', () {
      final result = findClosestModel('BMW X1', knownModels);
      expect(result, 'BMW X1');
    });

    test('still corrects a genuine OCR typo with no digits', () {
      final result = findClosestModel('HYUNDAI TUCSCA', knownModels);
      expect(result, 'HYUNDAI TUCSON');
    });

    test('still corrects ALFA misread with matching digits (none present)', () {
      final result = findClosestModel('ALEA ROMEO JUNIOR', knownModels);
      expect(result, 'ALFA ROMEO JUNIOR');
    });
  });
}