/// Shared regex patterns for LNU enrolment / assessment form OCR.

/// Enrolment row code: A145, E177, etc.
final RegExp lnuEnrollmentCodePattern = RegExp(r'\b[A-Z]\s?\d{3,4}\b');

/// Subject codes: IT-122, EDUC-118, GE-117, PATHFIT-4, PROF ED-109.
final RegExp lnuSubjectCodePattern = RegExp(
  r'\b(?:PATHFIT-\d{1,3}|PROF\s+ED-\d{1,4}|[A-Z]{2,6}-\d{1,4}L?)\b',
  caseSensitive: false,
);

/// Section: AI31, EE22.
final RegExp lnuSectionCodePattern = RegExp(r'\b[A-Z]{2}\d{2}\b');

/// Room codes on LNU slips.
const String lnuRoomPatternSource = r'(?:'
    r'COMLAB\d+[A-Z]?|'
    r'CISCOLAB|'
    r'CON\d+[A-Z]?|'
    r'ACAD\d+[A-Z]?|'
    r'MSR\d+[A-Z]?|'
    r'PMF\d+[A-Z]?|'
    r'ILS-[A-Z0-9]+|'
    r'TBA\d*[A-Z]?'
    r')';

final RegExp lnuRoomCodePattern = RegExp(
  '($lnuRoomPatternSource)\\b',
  caseSensitive: false,
);

/// Time range: 7:30-9 am, 10:30 am-12 pm, 8-10 am.
final RegExp lnuScheduleTimePattern = RegExp(
  r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*-\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)',
  caseSensitive: false,
);

bool looksLikeSectionCode(String token) =>
    lnuSectionCodePattern.hasMatch(token) && token.length <= 5;

bool looksLikeEnrollmentCode(String token) =>
    lnuEnrollmentCodePattern.hasMatch(token);

String normalizeSubjectCodeToken(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (RegExp(r'^PROF\s+ED-', caseSensitive: false).hasMatch(s)) {
    return s.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }
  return s.replaceAll(RegExp(r'\s+'), '').toUpperCase();
}
