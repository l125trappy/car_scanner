import 'known_models.dart';


class OcrLine {
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;

  OcrLine({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class CarRow {
  final String plate;
  final String unit;
  final String location;

  CarRow({required this.plate, required this.unit, required this.location});

  @override
  String toString() => 'CarRow(plate: $plate, unit: $unit, location: $location)';
}

final RegExp _plateAndRestPattern = RegExp(
  r'^([A-Z0-9]{1,3}-[A-Z0-9]{1,3}-[A-Z0-9]{1,3})\s+(\d{6,8})\s+(.+)$',
);

CarRow? tryParseFullRow(String text) {
  final cleaned = text.trim().toUpperCase();
  final match = _plateAndRestPattern.firstMatch(cleaned);

  if (match == null) return null;

  final plate = match.group(1)!;
  final unit = match.group(2)!;
  final location = match.group(3)!.replaceAll(' ', '');

  return CarRow(plate: plate, unit: unit, location: location);
}

List<List<OcrLine>> groupLinesIntoRows(List<OcrLine> lines) {
  if (lines.isEmpty) return [];

  final sorted = List<OcrLine>.from(lines)
    ..sort((a, b) => a.y.compareTo(b.y));

  final averageHeight =
      sorted.map((l) => l.height).reduce((a, b) => a + b) / sorted.length;
  final rowThreshold = averageHeight * 0.6;

  final List<List<OcrLine>> rows = [];
  List<OcrLine> currentRow = [sorted.first];

  for (int i = 1; i < sorted.length; i++) {
    final line = sorted[i];
    final rowAverageY =
        currentRow.map((l) => l.y).reduce((a, b) => a + b) / currentRow.length;

    if ((line.y - rowAverageY).abs() <= rowThreshold) {
      currentRow.add(line);
    } else {
      rows.add(currentRow);
      currentRow = [line];
    }
  }
  rows.add(currentRow);

  for (final row in rows) {
    row.sort((a, b) => a.x.compareTo(b.x));
  }

  return rows;
}

CarRow? rowToCarRow(List<OcrLine> row) {
  if (row.isEmpty) return null;

  final combinedText = row.map((l) => l.text).join(' ');
  return tryParseFullRow(combinedText);
}


const Set<String> _knownLabels = {
  'TYPE/KENT.',
  'UNIT',
  'LAATSTE',
  'LOKATIE',
};

bool isHeaderRow(List<OcrLine> row, CarRow? parsedRow) {
  if (parsedRow != null) return false;
  if (row.length != 1) return false;

  final text = row.first.text.trim().toUpperCase();
  if (_knownLabels.contains(text)) return false;
  if (text.isEmpty) return false;

  return true;
}

final RegExp _plateOnlyPattern = RegExp(
  r'^[A-Z0-9]{1,3}-[A-Z0-9]{1,3}-[A-Z0-9]{1,3}$',
);

bool looksLikePlateOnly(String text) {
  return _plateOnlyPattern.hasMatch(text.trim().toUpperCase());
}

List<CarRow> reconstructCarRows(List<OcrLine> lines) {
  final List<CarRow> results = [];
  final List<OcrLine> plateFragments = [];
  final List<OcrLine> restFragments = [];
  final Set<OcrLine> usedRestFragments = {};
  final List<double> mergedWidths = [];

  for (final l in lines) {
    final fullRow = tryParseFullRow(l.text);
    if (fullRow != null) {
      results.add(fullRow);
      mergedWidths.add(l.width);
    } else if (looksLikePlateOnly(l.text)) {
      plateFragments.add(l);
    } else {
      restFragments.add(l);
    }
  }

  final maxDistance = mergedWidths.isNotEmpty
      ? mergedWidths.reduce((a, b) => a > b ? a : b) * 1.2
      : 500.0;

  final averageHeight = lines.isNotEmpty
      ? lines.map((l) => l.height).reduce((a, b) => a + b) / lines.length
      : 15.0;
  final rowThreshold = averageHeight * 0.6;

  for (final plate in plateFragments) {
    OcrLine? bestMatch;
    double bestXDistance = double.infinity;

    for (final rest in restFragments) {
      if (usedRestFragments.contains(rest)) continue;

      final xDistance = rest.x - plate.x;
      if (xDistance <= 0 || xDistance > maxDistance) continue;

      final yDistance = (rest.y - plate.y).abs();
      if (yDistance > rowThreshold) continue;

      if (xDistance < bestXDistance) {
        bestXDistance = xDistance;
        bestMatch = rest;
      }
    }

    if (bestMatch != null) {
      usedRestFragments.add(bestMatch);
      final parsed = tryParseFullRow('${plate.text} ${bestMatch.text}');
      if (parsed != null) {
        results.add(parsed);
      }
    }
  }

  return results;
}

final RegExp _unitLocationPattern = RegExp(r'^\d{6,8}\b');

bool looksLikeUnitLocationFragment(String text) {
  return _unitLocationPattern.hasMatch(text.trim());
}


final RegExp _plateSubstringPattern = RegExp(r'[A-Z0-9]{1,3}-[A-Z0-9]{1,3}-[A-Z0-9]{1,3}');

String? extractPlateSubstring(String rawText) {
  final cleaned = rawText.trim().toUpperCase();
  final match = _plateSubstringPattern.firstMatch(cleaned);
  return match?.group(0);
}


class CarEntry {
  final String? model;
  final CarRow carRow;

  CarEntry({required this.model, required this.carRow});

  @override
  String toString() => 'CarEntry(model: $model, $carRow)';
}

List<CarEntry> parseOcrLines(List<OcrLine> lines) {
  final List<OcrLine> headers = [];
  final List<OcrLine> plateFragments = [];
  final List<OcrLine> restFragments = [];
  final List<MapEntry<OcrLine, CarRow>> positionedRows = [];

  for (final l in lines) {
    final text = l.text.trim();
    final upper = text.toUpperCase();

    if (_knownLabels.contains(upper)) continue;

    final fullRow = tryParseFullRow(text);
    if (fullRow != null) {
      positionedRows.add(MapEntry(l, fullRow));
    } else if (looksLikePlateOnly(text)) {
      plateFragments.add(l);
    } else if (looksLikeUnitLocationFragment(text)) {
      restFragments.add(l);
    } else if (text.isNotEmpty && !text.contains('-')) {
      headers.add(l);
    }
  }

  final maxDistance = positionedRows.isNotEmpty
      ? positionedRows.map((e) => e.key.width).reduce((a, b) => a > b ? a : b) * 1.2
      : 500.0;

  final averageHeight = lines.isNotEmpty
      ? lines.map((l) => l.height).reduce((a, b) => a + b) / lines.length
      : 15.0;
  final rowThreshold = averageHeight * 0.6;

  final Set<OcrLine> usedRest = {};

  for (final plate in plateFragments) {
    OcrLine? bestMatch;
    double bestXDistance = double.infinity;

    for (final rest in restFragments) {
      if (usedRest.contains(rest)) continue;
      final xDistance = rest.x - plate.x;
      if (xDistance <= 0 || xDistance > maxDistance) continue;
      final yDistance = (rest.y - plate.y).abs();
      if (yDistance > rowThreshold) continue;

      if (xDistance < bestXDistance) {
        bestXDistance = xDistance;
        bestMatch = rest;
      }
    }

    if (bestMatch != null) {
      usedRest.add(bestMatch);
      final parsed = tryParseFullRow('${plate.text} ${bestMatch.text}');
      if (parsed != null) {
        positionedRows.add(MapEntry(plate, parsed));
      }
    }
  }

  const xTolerance = 25.0;

  String? findModel(OcrLine rowLine) {
    OcrLine? best;
    for (final h in headers) {
      if (h.y >= rowLine.y) continue;
      if ((h.x - rowLine.x).abs() > xTolerance) continue;
      if (best == null || h.y > best.y) best = h;
    }
    if (best == null) return null;
    return findClosestModel(best.text.trim(), knownModels);
  }

  return positionedRows
      .map((e) => CarEntry(model: findModel(e.key), carRow: e.value))
      .toList();
}


String normalizeForComparison(String text) {
  return text.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}


int _levenshteinDistance(String a, String b) {
  final m = a.length;
  final n = b.length;
  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

  for (int i = 0; i <= m; i++){
    dp[i][0] = i;
  }
  for (int j = 0; j <= n; j++){
    dp[0][j] = j;
  }

  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      if (a[i - 1] == b[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
            .reduce((x, y) => x < y ? x : y);
      }
    }
  }

  return dp[m][n];
}

String findClosestModel(String detected, List<String> candidates) {
  final cleaned = detected.trim().toUpperCase();
  final detectedDigits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');

  String bestMatch = detected;
  int bestDistance = 999;

  for (final candidate in candidates) {
    final candidateDigits = candidate.replaceAll(RegExp(r'[^0-9]'), '');

    if (detectedDigits.isNotEmpty && detectedDigits != candidateDigits) {
      continue;
    }

    final distance = _levenshteinDistance(cleaned, candidate);
    if (distance < bestDistance) {
      bestDistance = distance;
      bestMatch = candidate;
    }
  }

  final maxAllowedDistance = (cleaned.length * 0.3).ceil().clamp(1, 6);

  if (bestDistance <= maxAllowedDistance) {
    return bestMatch;
  }

  return detected;
}



const Set<String> _ignoredFragments = {
  'NL',
  'EU',
  'NLD',
};

String extractPlateText(String rawText) {
  final lines = rawText.split('\n');

  final filtered = lines.where((line) {
    final cleaned = normalizeForComparison(line);
    if (cleaned.isEmpty) return false;
    if (_ignoredFragments.contains(cleaned)) return false;
    if (cleaned.length <= 2) return false;
    return true;
  }).toList();

  return filtered.join(' ');
}

String extractPlateTextFiltered(List<OcrLine> lines) {
  if (lines.isEmpty) return '';

  final maxHeight = lines.map((l) => l.height).reduce((a, b) => a > b ? a : b);
  final heightThreshold = maxHeight * 0.55;

  final filtered = lines.where((line) {
    if (line.height < heightThreshold) return false;

    final cleaned = normalizeForComparison(line.text);
    if (cleaned.isEmpty) return false;
    if (_ignoredFragments.contains(cleaned)) return false;
    if (cleaned.length <= 1) return false;

    return true;
  }).toList();

  return filtered.map((l) => l.text).join(' ');
}