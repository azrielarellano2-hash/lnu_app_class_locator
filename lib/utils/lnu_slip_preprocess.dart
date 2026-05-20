/// Normalizes raw ML Kit OCR text before enrolment table parsing.

String preprocessEslipOcrText(String raw) {
  var s = raw.replaceAll(RegExp(r'\r\n?'), '\n');
  s = s.replaceAll(RegExp(r'[–—−]'), '-');
  s = s.replaceAll(RegExp(r'\bp\.m\.', caseSensitive: false), 'pm');
  s = s.replaceAll(RegExp(r'\ba\.m\.', caseSensitive: false), 'am');

  // Enrolment codes: A 145, E 177 (not PROF ED).
  s = s.replaceAllMapped(
    RegExp(r'(?:^|[\n\r])\s*([A-Z])\s+(\d{3,4})\b'),
    (m) => '${m.group(1)}${m.group(2)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'\b([A-E])\s+(\d{3,4})\b(?!\s*-\d)'),
    (m) => '${m.group(1)}${m.group(2)}',
  );

  // Rooms — collapse OCR spacing.
  s = s.replaceAll(RegExp(r'COM\s*LAB', caseSensitive: false), 'COMLAB');
  s = s.replaceAll(RegExp(r'CISCO\s*LAB', caseSensitive: false), 'CISCOLAB');
  s = s.replaceAllMapped(
    RegExp(r'\b(MSR|PMF|ACAD|CON)\s*(\d)', caseSensitive: false),
    (m) => '${m.group(1)}${m.group(2)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'\bT\s*BA(\d*)', caseSensitive: false),
    (m) => 'TBA${m.group(1)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'COMLAB\s*(\d)', caseSensitive: false),
    (m) => 'COMLAB${m.group(1)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'\bILS\s*-\s*([A-Z0-9]+)', caseSensitive: false),
    (m) => 'ILS-${m.group(1)}',
  );

  // Day tokens.
  s = s.replaceAll(RegExp(r'\bM\s+Th\b', caseSensitive: false), 'MTh');
  s = s.replaceAll(RegExp(r'\bT\s+F\b', caseSensitive: false), 'TF');
  s = s.replaceAll(RegExp(r'\bT\s*[/\-]\s*F\b', caseSensitive: false), 'TF');
  s = s.replaceAll(RegExp(r'\bTTH\b'), 'TF');
  s = s.replaceAll(RegExp(r'\bTUTH\b'), 'TF');
  s = s.replaceAll(RegExp(r'\bTUF\b'), 'TF');
  s = s.replaceAll(RegExp(r'\bNTh\b'), 'MTh');
  s = s.replaceAll(RegExp(r'\bMTH\b'), 'MTh');
  s = s.replaceAll(RegExp(r'\bMT\s*h\b', caseSensitive: false), 'MTh');
  s = s.replaceAll(RegExp(r'\bWed(?:nesday)?\b', caseSensitive: false), ' W ');
  s = s.replaceAll(RegExp(r'\bWED\b'), ' W ');

  // Subject codes — spacing variants.
  s = s.replaceAll(
    RegExp(r'PROF\s+ED\s*-\s*', caseSensitive: false),
    'PROF ED-',
  );
  s = s.replaceAllMapped(
    RegExp(
      r'\b(EDUC|GE|IT|PATHFIT)\s*-\s*(\d)',
      caseSensitive: false,
    ),
    (m) => '${m.group(1)}-${m.group(2)}',
  );

  // Meridiem glued to day or time.
  s = s.replaceAllMapped(
    RegExp(
      r'(am|pm)(MTh|TF|SS|MWF|MW|W)(?![A-Za-z])',
      caseSensitive: false,
    ),
    (m) => '${m.group(1)} ${m.group(2)}',
  );
  s = s.replaceAllMapped(
    RegExp(
      r'(\d{1,2}:\d{2}-\d{1,2})(am|pm)\b',
      caseSensitive: false,
    ),
    (m) => '${m.group(1)} ${m.group(2)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'(\d{1,2}-\d{1,2}(?::\d{2})?)(am|pm)\b', caseSensitive: false),
    (m) => '${m.group(1)} ${m.group(2)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'(\d{1,2}(?::\d{2})?)\s*(am|pm)\s*-\s*(\d)', caseSensitive: false),
    (m) => '${m.group(1)} ${m.group(2)}-${m.group(3)}',
  );
  // Only split meridiem glued to letters after a digit (e.g. 8amMTh), not PM in PMF15A.
  s = s.replaceAllMapped(
    RegExp(r'(?<=\d)(am|pm)(?=[A-Za-z])', caseSensitive: false),
    (m) => '${m.group(1)} ',
  );
  s = s.replaceAllMapped(
    RegExp(
      r'(am|pm)\s*W\s*(?=COMLAB|CISCOLAB|TBA|CON|ACAD|MSR|PMF|ILS)',
      caseSensitive: false,
    ),
    (m) => '${m.group(1)} W ',
  );

  s = s.replaceAllMapped(
    RegExp(r'\bAl(\d{2})\b'),
    (m) => 'AI${m.group(1)}',
  );

  // IT - 122L (skip AI31 section).
  s = s.replaceAllMapped(
    RegExp(r'\b([A-Z]{2,6})\s*-\s*(\d{1,4})(L)?\b'),
    (m) {
      final dept = m.group(1)!.toUpperCase();
      if (dept == 'PROF') return m.group(0)!;
      if (dept == 'AI' && (m.group(2)?.length ?? 0) <= 2) {
        return m.group(0)!;
      }
      return '$dept-${m.group(2)}${m.group(3) ?? ''}';
    },
  );

  s = s.replaceAllMapped(
    RegExp(r'(\d)\s+-\s+(\d)'),
    (m) => '${m.group(1)}-${m.group(2)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'(\d{1,2})\s*:\s*(\d{2})'),
    (m) => '${m.group(1)}:${m.group(2)}',
  );

  s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
  return s;
}
