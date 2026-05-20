/**
 * LNU e-slip schedule parser (reference implementation).
 * Strict token-based day mapping — no single-character splitting.
 */

export const DAY_MAP: Record<string, string[]> = {
  MTh: ['Monday', 'Thursday'],
  TF: ['Tuesday', 'Friday'],
  W: ['Wednesday'],
  SS: ['Saturday', 'Sunday'],
};

const DAY_TOKENS_LONGEST_FIRST = ['MTh', 'TF', 'SS', 'W'] as const;
type DayToken = (typeof DAY_TOKENS_LONGEST_FIRST)[number];

const OCR_DAY_FIXES: Record<string, DayToken> = {
  MTH: 'MTh',
  NTH: 'MTh',
  NTh: 'MTh',
  MT: 'MTh',
  TTH: 'TF',
  TUTH: 'TF',
  WED: 'W',
  WEDNESDAY: 'W',
};

export function normalizeOcrText(raw: string): string {
  let s = raw.replace(/\r\n?/g, '\n');
  s = s.replace(/\bNTh\b/g, 'MTh');
  s = s.replace(/\bMTH\b/g, 'MTh');
  s = s.replace(/\bM\s+Th\b/gi, 'MTh');
  s = s.replace(/\bT\s+F\b/gi, 'TF');
  s = s.replace(/\bWed(?:nesday)?\b/gi, ' W ');
  s = s.replace(/(\d{1,2}-\d{1,2}(?::\d{2})?)(am|pm)\b/gi, '$1 $2');
  s = s.replace(/(am|pm)(MTh|TF|SS|W)\b/gi, '$1 $2');
  s = s.replace(/\bCOM\s*LAB/gi, 'COMLAB');
  s = s.replace(/\bA\s+(\d{3,4})\b/g, 'A$1');
  return s.replace(/[ \t]+/g, ' ').trim();
}

export function canonicalizeDayToken(raw: string): DayToken | null {
  const trimmed = raw.trim();
  if ((DAY_MAP as Record<string, string[]>)[trimmed]) return trimmed as DayToken;

  const collapsed = trimmed.replace(/\s+/g, '');
  const upper = collapsed.toUpperCase();
  if (OCR_DAY_FIXES[upper]) return OCR_DAY_FIXES[upper];
  if (OCR_DAY_FIXES[collapsed]) return OCR_DAY_FIXES[collapsed];

  for (const tok of DAY_TOKENS_LONGEST_FIRST) {
    if (collapsed === tok || collapsed.endsWith(tok)) return tok;
    if (new RegExp(`(?:^|\\s)${tok}$`).test(trimmed)) return tok;
  }
  if (/(?:^|\s)W$/.test(trimmed)) return 'W';
  return null;
}

const ROOM_RE = /(COMLAB\d+[A-Z]?|TBA\d+[A-Z]?|CISCOLAB|CON\d+[A-Z]?)/i;
const TIME_RE =
  /(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*-\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)/i;
const SUBJECT_RE = /[A-Z]{2,3}-\d{2,4}L\b|[A-Z]{2,3}-\d{2,4}(?![0-9A-Za-z])/g;
const CODE_RE = /\bA\d{3,4}\b/;

export interface ParsedRow {
  code: string;
  subject: string;
  scheduleAndRoom: string;
  dayToken: DayToken;
  room: string;
  days: string[];
}

export function extractDayFromSchedule(scheduleAndRoom: string): DayToken | null {
  const room = ROOM_RE.exec(scheduleAndRoom);
  if (!room) return null;
  const beforeRoom = scheduleAndRoom.slice(0, room.index).trim();
  return canonicalizeDayToken(beforeRoom.replace(TIME_RE, '').trim());
}

export function dedupeByEnrollmentCode(rows: ParsedRow[]): ParsedRow[] {
  const map = new Map<string, ParsedRow>();
  for (const row of rows) {
    const key = row.code || `${row.subject}|${row.scheduleAndRoom}`;
    const prev = map.get(key);
    if (!prev) {
      map.set(key, row);
      continue;
    }
    if (prev.subject !== row.subject) {
      map.set(`${key}|${row.subject}`, row);
      continue;
    }
  }
  return [...map.values()];
}

// Example
if (require.main === module) {
  const sample = normalizeOcrText(`
A147 IT-121 Information Management I 2 8-10am W CISCOLAB AI31 D. Funcion
A146 IT-121L Information Management I 1 1 9-10:30 am MTh COMLAB4A AI31 D. Funcion
A145 IT-122 System Analysis and Design 2 8-9 am MTh COMLAB2A AI31 M. Gotardo
`);
  for (const line of sample.split('\n').filter(Boolean)) {
    const sched = line.match(
      /\d{1,2}(?::\d{2})?\s*(?:am|pm)?\s*-\s*\d{1,2}(?::\d{2})?\s*(?:am|pm)\s+\S+\s+(?:COMLAB\d+\w*|TBA\d+\w*|CISCOLAB|CON\d+\w*)/i,
    )?.[0];
    const day = sched ? extractDayFromSchedule(sched) : null;
    console.log(line.slice(0, 40), '→', day, day ? DAY_MAP[day] : null);
  }
}
