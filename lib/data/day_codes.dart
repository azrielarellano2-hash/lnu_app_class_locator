// LNU schedule day tokens — longest-match-first (never split MTh into M+T+h).

/// Weekday index: 0 = Monday … 6 = Sunday.
const Map<String, List<int>> kDayMap = {
  'MTh': [0, 3],
  'TF': [1, 4],
  'SS': [5, 6],
  'Th': [3],
  'M': [0],
  'T': [1],
  'W': [2],
  'F': [4],
  'S': [5],
};

const Map<String, String> kDayReadable = {
  'MTh': 'Monday and Thursday',
  'TF': 'Tuesday and Friday',
  'SS': 'Saturday and Sunday',
  'Th': 'Thursday',
  'M': 'Monday',
  'T': 'Tuesday',
  'W': 'Wednesday',
  'F': 'Friday',
  'S': 'Saturday',
};

/// Priority order when scanning schedule text (longest first).
const List<String> kDayTokenPriority = [
  'MTh',
  'TF',
  'SS',
  'Th',
  'M',
  'T',
  'W',
  'F',
  'S',
];

const Map<String, String> kOcrDayTokenFixes = {
  'MTH': 'MTh',
  'NTH': 'MTh',
  'NTh': 'MTh',
  'MT': 'MTh',
  'TTH': 'TF',
  'TUTH': 'TF',
  'TUF': 'TF',
  'TRF': 'TF',
  'WED': 'W',
  'WEDNESDAY': 'W',
};

const Map<String, String> kReadablePhraseToToken = {
  'monday and thursday': 'MTh',
  'tuesday and friday': 'TF',
  'saturday and sunday': 'SS',
};

const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String normalizeDayPattern(String raw) =>
    raw.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();

String normalizeDayToken(String raw) => raw.trim();

String normalizeOcrDayBlob(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'\s+'), '');
  if (s.isEmpty) return s;
  if (s == 'NTh' || s == 'nTh') return 'MTh';
  final upper = s.toUpperCase();
  return kOcrDayTokenFixes[upper] ?? kOcrDayTokenFixes[s] ?? s;
}

bool _isAsciiLetter(String c) =>
    c.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(c);

bool _meridiemTouchesIndex(String s, int index) {
  if (index <= 0) return false;
  final start = index >= 2 ? index - 2 : 0;
  final chunk = s.substring(start, index).toLowerCase();
  return chunk.endsWith('am') || chunk.endsWith('pm');
}

bool _dayTokenAt(String s, int i, String tok) {
  if (i + tok.length > s.length) return false;
  if (s.substring(i, i + tok.length).toUpperCase() != tok.toUpperCase()) {
    return false;
  }
  final before = i > 0 ? s[i - 1] : '';
  final after =
      i + tok.length < s.length ? s[i + tok.length] : '';
  if (_isAsciiLetter(after)) return false;
  if (_isAsciiLetter(before) && !_meridiemTouchesIndex(s, i)) return false;
  return true;
}

/// Longest-match scan — consumes MTh as one token, not M+Th.
List<String> extractDayTokensFromBlob(String blob) {
  final s = blob.replaceAll(RegExp(r'\s+'), '');
  final found = <String>[];
  var i = 0;
  while (i < s.length) {
    String? matched;
    for (final tok in kDayTokenPriority) {
      if (_dayTokenAt(s, i, tok)) {
        matched = tok;
        break;
      }
    }
    if (matched == null) {
      i++;
      continue;
    }
    found.add(matched);
    i += matched.length;
  }
  return found;
}

String? canonicalizeEslipDayToken(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  if (kDayMap.containsKey(trimmed)) return trimmed;

  final lowerPhrase = trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (kReadablePhraseToToken.containsKey(lowerPhrase)) {
    return kReadablePhraseToToken[lowerPhrase];
  }

  final collapsed = trimmed.replaceAll(RegExp(r'\s+'), '');
  final fixed = normalizeOcrDayBlob(collapsed);
  if (kDayMap.containsKey(fixed)) return fixed;

  final scanned = extractDayTokensFromBlob(collapsed);
  if (scanned.isNotEmpty) return scanned.last;

  for (final tok in kDayTokenPriority) {
    if (RegExp(r'(?:^|\s)' + RegExp.escape(tok) + r'(?:\s|$)', caseSensitive: false)
        .hasMatch(trimmed)) {
      return tok;
    }
  }
  if (RegExp(r'(?:^|\s)W$', caseSensitive: false).hasMatch(trimmed)) return 'W';
  return null;
}

/// Infers MTh / TF / W / SS from stored weekday indices (0 = Mon … 6 = Sun).
String? dayTokenFromWeekdayIndices(Set<int> weekdayIndices) {
  if (weekdayIndices.isEmpty) return null;
  final sorted = weekdayIndices.toList()..sort();

  if (sorted.contains(0) && sorted.contains(3)) return 'MTh';
  if (sorted.contains(1) && sorted.contains(4)) return 'TF';
  if (sorted.contains(5) && sorted.contains(6)) return 'SS';
  if (sorted.length == 1) {
    const singles = {
      0: 'M',
      1: 'T',
      2: 'W',
      3: 'Th',
      4: 'F',
      5: 'S',
      6: 'S',
    };
    return singles[sorted.first];
  }
  return null;
}

List<int> expandEslipDayToken(String token) => weekdayIndicesForToken(token);

List<int> weekdayIndicesForToken(String token) {
  final canonical = canonicalizeEslipDayToken(token);
  if (canonical == null) {
    throw FormatException('Unknown day token: $token');
  }
  return List<int>.from(kDayMap[canonical]!);
}

List<String> weekdayNamesForToken(String token) {
  final indices = weekdayIndicesForToken(token);
  return indices.map((i) => _weekdayNames[i]).toList();
}

String readableDayPattern(String token) {
  final canonical = canonicalizeEslipDayToken(token) ?? token.trim();
  return kDayReadable[canonical] ?? canonical;
}

/// Day token between time and room in a schedule column.
String? matchScheduleDayToken(String beforeRoom) {
  final tail = beforeRoom.trim();
  if (tail.isEmpty) return null;

  // Prefer the day token immediately before the room (official slip layout).
  for (final tok in kDayTokenPriority) {
    final re = RegExp(
      r'\b' + RegExp.escape(tok) + r'\s*$',
      caseSensitive: false,
    );
    if (re.hasMatch(tail)) return tok;
  }

  final collapsed = tail.replaceAll(RegExp(r'\s+'), '');
  final scanned = extractDayTokensFromBlob(collapsed);
  if (scanned.isNotEmpty) return scanned.last;

  return canonicalizeEslipDayToken(tail);
}

// Backward-compatible aliases
const Map<String, List<int>> kEslipDayIndices = kDayMap;
const Map<String, String> kEslipDayReadable = kDayReadable;
const List<String> kEslipDayTokensLongestFirst = kDayTokenPriority;

List<int> expandDayPattern(String pattern) {
  final canonical = canonicalizeEslipDayToken(pattern);
  if (canonical != null) return weekdayIndicesForToken(canonical);
  throw FormatException('Unknown day pattern: $pattern');
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
