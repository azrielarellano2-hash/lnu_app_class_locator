import 'package:flutter/material.dart';

import '../models/validated_eslip_row.dart';
import '../utils/debug_agent_log.dart';
import '../utils/eslip_ocr_parser.dart';

/// On-screen LNU e-slip table (no Flutter [Table] — reliable inside scroll views).
class EslipTableWidget extends StatelessWidget {
  const EslipTableWidget({
    super.key,
    required this.profile,
    required this.rows,
  });

  final EslipParsedProfile profile;
  final List<ValidatedEslipRow> rows;

  static const _tableWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    // #region agent log
    agentDebugLog(
      location: 'eslip_table_widget.dart:build',
      message: 'table_build',
      hypothesisId: 'H2',
      runId: 'post-fix',
      data: {'rowCount': rows.length},
    );
    // #endregion

    final scheme = Theme.of(context).colorScheme;
    var totalUnits = 0;
    var totalLab = 0;
    for (final r in rows) {
      totalUnits += int.tryParse(r.units) ?? 0;
      totalLab += int.tryParse(r.lab) ?? 0;
    }

    final border = Border.all(color: scheme.outline.withValues(alpha: 0.45));
    final headerBg = scheme.primaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _headerBlock(context),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _tableWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _gridRow(
                  _headers,
                  background: headerBg,
                  bold: true,
                  border: border,
                ),
                ...rows.asMap().entries.map((e) {
                  final r = e.value;
                  return _gridRow(
                    [
                      r.enrollmentCode ?? '',
                      r.subjectCode,
                      r.description,
                      r.units,
                      r.lab,
                      r.scheduleRaw,
                      r.section,
                      r.instructor,
                    ],
                    background: e.key.isOdd
                        ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
                        : null,
                    border: border,
                  );
                }),
                _gridRow(
                  ['Total Units: $totalUnits $totalLab', '', '', '', '', '', '', ''],
                  bold: true,
                  border: border,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _headers = [
    'CODE',
    'SUBJECT',
    'DESCRIPTION',
    'UNITS',
    'LAB',
    'SCHEDULE AND ROOM',
    'SECTION',
    'INSTRUCTOR',
  ];

  static const _colFlex = [1, 1, 3, 1, 1, 2, 1, 2];

  Widget _gridRow(
    List<String> cells, {
    Color? background,
    bool bold = false,
    required Border border,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        border: border,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(8, (i) {
          final text = i < cells.length ? cells[i] : '';
          return Expanded(
            flex: _colFlex[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _headerBlock(BuildContext context) {
    final ay = profile.academicYear ?? '';
    final sem = profile.semester ?? 'First Semester';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'LEYTE NORMAL UNIVERSITY',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            Text(
              '$sem ${ay.isNotEmpty ? ay : ''}'.trim(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const Row(
          children: [
            Expanded(child: Text('Tacloban City, Leyte')),
            Text('Enrolment and Assessment Form'),
          ],
        ),
        if (profile.formNumber != null) Text('Form No. ${profile.formNumber}'),
        const SizedBox(height: 8),
        Text(
          'ID No: ${profile.studentId ?? '—'}  '
          'Name: ${profile.fullName ?? '—'}  '
          'Year: ${profile.year ?? '—'}  '
          'Date: ${profile.enrolmentDate ?? '—'}',
        ),
        Text('College: ${profile.college ?? '—'}'),
        Text('Course: ${profile.course ?? '—'}'),
      ],
    );
  }
}
