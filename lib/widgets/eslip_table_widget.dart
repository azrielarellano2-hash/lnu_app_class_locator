import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../models/validated_eslip_row.dart';
import '../utils/eslip_ocr_parser.dart';
import '../utils/eslip_printable_rows.dart';

/// On-screen layout matching the official LNU Enrolment and Assessment Form.
class EslipTableWidget extends StatelessWidget {
  const EslipTableWidget({
    super.key,
    required this.profile,
    required this.rows,
  });

  final EslipParsedProfile profile;
  final List<ValidatedEslipRow> rows;

  static const _tableWidth = 760.0;

  @override
  Widget build(BuildContext context) {
    final sorted = List<ValidatedEslipRow>.from(rows);
    sortEslipRowsByCode(sorted);
    final totals = eslipUnitTotals(sorted);
    final border = Border.all(color: Colors.black87, width: 0.6);
    const cellStyle = TextStyle(fontSize: 10, height: 1.2);
    const headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _headerBlock(),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _tableWidth,
            child: Table(
              border: TableBorder.all(color: Colors.black87, width: 0.6),
              columnWidths: const {
                0: FixedColumnWidth(44),
                1: FixedColumnWidth(52),
                2: FlexColumnWidth(2.6),
                3: FixedColumnWidth(36),
                4: FixedColumnWidth(32),
                5: FlexColumnWidth(2.1),
                6: FixedColumnWidth(44),
                7: FlexColumnWidth(1.5),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: _headers
                      .map(
                        (h) => _tableCell(
                          h,
                          style: headerStyle,
                          center: true,
                          border: border,
                        ),
                      )
                      .toList(),
                ),
                ...sorted.map(
                  (r) => TableRow(
                    children: [
                      _tableCell(r.enrollmentCode ?? '', center: true, border: border, style: cellStyle),
                      _tableCell(r.subjectCode, center: true, border: border, style: cellStyle),
                      _tableCell(r.description, border: border, style: cellStyle),
                      _tableCell(r.units, center: true, border: border, style: cellStyle),
                      _tableCell(eslipLabCell(r.lab), center: true, border: border, style: cellStyle),
                      _tableCell(eslipScheduleCell(r), border: border, style: cellStyle),
                      _tableCell(r.section, center: true, border: border, style: cellStyle),
                      _tableCell(r.instructor, border: border, style: cellStyle),
                    ],
                  ),
                ),
                TableRow(
                  children: [
                    _tableCell('', border: border),
                    _tableCell('', border: border),
                    _tableCell(
                      'Total Units:',
                      border: border,
                      style: headerStyle,
                      alignRight: true,
                    ),
                    _tableCell(
                      '${totals.$1}',
                      center: true,
                      border: border,
                      style: headerStyle,
                    ),
                    _tableCell(
                      totals.$2 > 0 ? '${totals.$2}' : '',
                      center: true,
                      border: border,
                      style: headerStyle,
                    ),
                    _tableCell('', border: border),
                    _tableCell('', border: border),
                    _tableCell('', border: border),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Assessment Details',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          'Tuition based on $totals lecture units · Laboratory and miscellaneous fees per university assessment.',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 8),
        Text(
          'Note: This is a system generated report. Signature/Stamp is not required.',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
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

  Widget _tableCell(
    String text, {
    required Border border,
    TextStyle style = const TextStyle(fontSize: 10),
    bool center = false,
    bool alignRight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Text(
        text,
        style: style,
        textAlign: alignRight
            ? TextAlign.right
            : center
                ? TextAlign.center
                : TextAlign.left,
      ),
    );
  }

  Widget _headerBlock() {
    final ay = profile.academicYear ?? '';
    final sem = profile.semester ?? 'First Semester';
    final formNo = profile.formNumber?.trim() ?? '';
    final date = profile.enrolmentDate?.trim().isNotEmpty == true
        ? profile.enrolmentDate!
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Image.asset(
                kLnuSealAsset,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                children: [
                  Text(
                    'LEYTE NORMAL UNIVERSITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  Text(
                    'Tacloban City, Leyte',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 168,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sem ${ay.isNotEmpty ? ay : ''}'.trim(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                  Text(
                    formNo.isNotEmpty
                        ? 'Enrolment and Assessment Form No. $formNo'
                        : 'Enrolment and Assessment Form',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 16, thickness: 1, color: Colors.black87),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _info('ID No:', profile.studentId),
                  _info('Name:', profile.fullName),
                  _info('Year:', profile.year),
                ],
              ),
            ),
            if (date.isNotEmpty) Text('Date: $date', style: const TextStyle(fontSize: 11)),
          ],
        ),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _info('College:', profile.college),
            _info('Section:', profile.section),
          ],
        ),
        _info('Course:', profile.course),
        const Divider(height: 12, thickness: 0.5, color: Colors.black54),
      ],
    );
  }

  Widget _info(String label, String? value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: Colors.black87),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' ${value?.trim().isNotEmpty == true ? value : '—'}'),
        ],
      ),
    );
  }
}
