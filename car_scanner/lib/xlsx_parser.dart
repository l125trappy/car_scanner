import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'ocr_parser.dart';

String _cellText(Data? cell) {
  final value = cell?.value;
  if (value == null) return '';

  if (value is IntCellValue) return value.value.toString();
  if (value is DoubleCellValue) {
    final d = value.value;
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toString();
  }
  if (value is TextCellValue) return value.value.toString().trim();

  return value.toString().trim();
}

List<CarEntry> parseXlsxBytes(Uint8List bytes) {
  final excelFile = Excel.decodeBytes(bytes);
  if (excelFile.tables.isEmpty) return [];

  final sheet = excelFile.tables[excelFile.tables.keys.first]!;

  int headerRowIndex = -1;
  for (int r = 0; r < sheet.maxRows; r++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r));
    if (_cellText(cell).toLowerCase() == 'type/kent.') {
      headerRowIndex = r;
      break;
    }
  }
  if (headerRowIndex == -1) return [];

  final dataStartRow = headerRowIndex + 2;

  final List<int> blockStarts = [];
  for (int c = 0; c < sheet.maxColumns; c++) {
    final headerCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRowIndex));
    if (_cellText(headerCell).toLowerCase() != 'type/kent.') continue;

    final thirdCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c + 2, rowIndex: headerRowIndex));
    if (_cellText(thirdCell).toLowerCase() == 'lokatie') {
      blockStarts.add(c);
    }
    // blocks labeled 'datum' are the sold-cars section — skipped for now
  }

  final List<CarEntry> entries = [];

  for (final blockStart in blockStarts) {
    String? currentModel;

    for (int r = dataStartRow; r < sheet.maxRows; r++) {
      final plateText = _cellText(sheet.cell(CellIndex.indexByColumnRow(columnIndex: blockStart, rowIndex: r)));
      final unitText = _cellText(sheet.cell(CellIndex.indexByColumnRow(columnIndex: blockStart + 1, rowIndex: r)));
      final locationText = _cellText(sheet.cell(CellIndex.indexByColumnRow(columnIndex: blockStart + 2, rowIndex: r)));

      if (plateText.isEmpty && unitText.isEmpty && locationText.isEmpty) continue;

      if (plateText.isNotEmpty && unitText.isEmpty && locationText.isEmpty) {
        currentModel = plateText.toUpperCase().trim();
        continue;
      }

      if (plateText.isNotEmpty && unitText.isNotEmpty && locationText.isNotEmpty) {
        entries.add(CarEntry(
          model: currentModel,
          carRow: CarRow(
            plate: plateText.toUpperCase(),
            unit: unitText,
            location: locationText.toUpperCase(),
          ),
        ));
      }
    }
  }

  return entries;
}