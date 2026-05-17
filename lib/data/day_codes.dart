// LNU-style day patterns → weekday indices (0 = Monday … 6 = Sunday).

final Map<String, List<int>> _patternMap = {
  'MWTH': [0, 2, 3],
  'MWF': [0, 2, 4],
  'MTF': [0, 1, 4],
  'MTH': [0, 3],
  'MT': [0, 3],
  'MW': [0, 2],
  'TF': [1, 4],
  'TTH': [1, 3],
  'TUTH': [1, 3],
  'SS': [5, 6],
  'SAT': [5],
  'SUN': [6],
  'SU': [6],
  'W': [2],
  'TH': [3],
  'F': [4],
  'M': [0],
  'T': [1],
  'S': [5],
};

String normalizeDayPattern(String raw) {
  return raw.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
}

/// Case-sensitive token normalization for ordered matching (MTh ≠ MTH conflation).
String normalizeDayToken(String raw) {
  return raw.trim();
}

/// Exact LNU e-slip tokens (case-sensitive) before generic pattern lookup.
const Map<String, List<int>> kEslipDayIndices = {
  'MTh': [0, 3],
  'W': [2],
  'TF': [1, 4],
  'SS': [5, 6],
};

/// Expands MTh / W / TF / SS exactly, then falls back to generic patterns (MWF, etc.).
List<int> expandEslipDayToken(String token) {
  final trimmed = token.trim();
  final exact = kEslipDayIndices[trimmed];
  if (exact != null) return List<int>.from(exact);
  return expandDayPattern(trimmed);
}

List<int> expandDayPattern(String pattern) {
  final key = normalizeDayPattern(pattern);
  final days = _patternMap[key];
  if (days == null) {
    throw FormatException('Unknown day pattern: $pattern');
  }
  return List<int>.from(days);
}

String normalizeTimeString(String raw) {
  var s = raw.trim().replaceAll('.', ':').replaceAll(RegExp(r'\s+'), '');
  final parts = s.split(':');
  if (parts.length < 2) {
    throw FormatException('Invalid time: $raw');
  }
  final h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
}
