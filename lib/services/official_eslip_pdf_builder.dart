import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/validated_eslip_row.dart';
import '../utils/app_logo_raster.dart' show loadLnuSealBytes;
import '../utils/eslip_ocr_parser.dart';
import '../utils/eslip_printable_rows.dart';

/// Official LNU Enrolment and Assessment Form layout (A4 portrait).
class OfficialEslipPdfBuilder {
  OfficialEslipPdfBuilder({
    required this.profile,
    required this.rows,
    this.logoImageBytes,
  });

  final EslipParsedProfile profile;
  final List<ValidatedEslipRow> rows;
  final Uint8List? logoImageBytes;

  static const _marginL = 24.0;
  static const _marginR = 24.0;
  static const _marginT = 18.0;
  static const _marginB = 18.0;

  pw.Font get _times => pw.Font.times();
  pw.Font get _timesBold => pw.Font.timesBold();

  pw.TextStyle _style({double size = 8, bool bold = false}) => pw.TextStyle(
        font: bold ? _timesBold : _times,
        fontSize: size,
      );

  String _dash(String? v) {
    if (v == null || v.trim().isEmpty) return '';
    return v.trim();
  }

  Future<Uint8List> build() async {
    final doc = pw.Document();
    final logoBytes = logoImageBytes ?? await loadLnuSealBytes();
    final sorted = List<ValidatedEslipRow>.from(rows);
    sortEslipRowsByCode(sorted);
    final totals = eslipUnitTotals(sorted);

    final sem = profile.semester ?? 'First Semester';
    final ay = profile.academicYear ?? '';
    final formNo = _dash(profile.formNumber);
    final dateStr = profile.enrolmentDate?.trim().isNotEmpty == true
        ? profile.enrolmentDate!
        : _formatDate(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(
          left: _marginL,
          right: _marginR,
          top: _marginT,
          bottom: _marginB,
        ),
        theme: pw.ThemeData.withFont(base: _times, bold: _timesBold),
        build: (context) => [
          _buildHeader(sem, ay, formNo, logoBytes),
          pw.SizedBox(height: 6),
          _buildStudentBlock(dateStr),
          pw.SizedBox(height: 4),
          _buildScheduleTable(sorted, totals.$1, totals.$2),
          pw.SizedBox(height: 10),
          _buildAssessmentSection(totals.$1),
          pw.SizedBox(height: 8),
          _buildPaymentSection(),
          pw.SizedBox(height: 10),
          _buildWithdrawalPolicy(),
          pw.SizedBox(height: 8),
          _buildSystemNote(),
        ],
      ),
    );

    return doc.save();
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m/$day/${d.year}';
  }

  pw.Widget _buildHeader(
    String sem,
    String ay,
    String formNo,
    Uint8List logoBytes,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(
              pw.MemoryImage(logoBytes),
              width: 52,
              height: 52,
              fit: pw.BoxFit.contain,
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    'LEYTE NORMAL UNIVERSITY',
                    style: _style(size: 17, bold: true),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'Tacloban City, Leyte',
                    style: _style(size: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(
              width: 155,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    '$sem ${ay.isNotEmpty ? ay : ''}'.trim(),
                    style: _style(size: 10, bold: true),
                    textAlign: pw.TextAlign.right,
                  ),
                  pw.Text(
                    formNo.isNotEmpty
                        ? 'Enrolment and Assessment Form No. $formNo'
                        : 'Enrolment and Assessment Form',
                    style: _style(size: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 0.75, color: PdfColors.black),
      ],
    );
  }

  pw.Widget _buildStudentBlock(String dateStr) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Wrap(
                spacing: 14,
                runSpacing: 2,
                children: [
                  _labelValue('ID No:', _dash(profile.studentId)),
                  _labelValue('Name:', _dash(profile.fullName)),
                  _labelValue('Year:', _dash(profile.year)),
                ],
              ),
            ),
            pw.Text('Date: $dateStr', style: _style(size: 9)),
          ],
        ),
        pw.Wrap(
          spacing: 14,
          runSpacing: 2,
          children: [
            _labelValue('College:', _dash(profile.college)),
            _labelValue('Section:', _dash(profile.section)),
          ],
        ),
        _labelValue('Course:', _dash(profile.course)),
        pw.SizedBox(height: 2),
        pw.Container(height: 0.5, color: PdfColors.black),
      ],
    );
  }

  pw.Widget _labelValue(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: label, style: _style(size: 9, bold: true)),
          pw.TextSpan(text: ' $value', style: _style(size: 9)),
        ],
      ),
    );
  }

  pw.Widget _buildScheduleTable(
    List<ValidatedEslipRow> sorted,
    int totalUnits,
    int totalLab,
  ) {
    const headers = [
      'CODE',
      'SUBJECT',
      'DESCRIPTION',
      'UNITS',
      'LAB',
      'SCHEDULE AND ROOM',
      'SECTION',
      'INSTRUCTOR',
    ];

    const colWidths = {
      0: pw.FixedColumnWidth(34),
      1: pw.FixedColumnWidth(44),
      2: pw.FlexColumnWidth(2.8),
      3: pw.FixedColumnWidth(30),
      4: pw.FixedColumnWidth(26),
      5: pw.FlexColumnWidth(2.2),
      6: pw.FixedColumnWidth(38),
      7: pw.FlexColumnWidth(1.6),
    };

    final border = pw.TableBorder.all(width: 0.5, color: PdfColors.black);

    pw.Widget cell(
      String text, {
      bool bold = false,
      pw.Alignment align = pw.Alignment.centerLeft,
      pw.TextAlign textAlign = pw.TextAlign.left,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        alignment: align,
        child: pw.Text(
          text,
          style: _style(size: 7.5, bold: bold),
          textAlign: textAlign,
        ),
      );
    }

    final dataRows = sorted.map((r) {
      final center = pw.Alignment.center;
      return pw.TableRow(
        children: [
          cell(_dash(r.enrollmentCode), align: center, textAlign: pw.TextAlign.center),
          cell(r.subjectCode, align: center, textAlign: pw.TextAlign.center),
          cell(r.description, align: pw.Alignment.centerLeft),
          cell(r.units, align: center, textAlign: pw.TextAlign.center),
          cell(eslipLabCell(r.lab), align: center, textAlign: pw.TextAlign.center),
          cell(eslipScheduleCell(r)),
          cell(r.section, align: center, textAlign: pw.TextAlign.center),
          cell(r.instructor),
        ],
      );
    }).toList();

    return pw.Table(
      border: border,
      columnWidths: colWidths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          children: headers
              .map(
                (h) => cell(
                  h,
                  bold: true,
                  align: pw.Alignment.center,
                  textAlign: pw.TextAlign.center,
                ),
              )
              .toList(),
        ),
        ...dataRows,
        pw.TableRow(
          children: [
            cell(''),
            cell(''),
            cell('Total Units:', bold: true, align: pw.Alignment.centerRight),
            cell('$totalUnits', bold: true, align: pw.Alignment.center, textAlign: pw.TextAlign.center),
            cell(totalLab > 0 ? '$totalLab' : '', bold: true, align: pw.Alignment.center, textAlign: pw.TextAlign.center),
            cell(''),
            cell(''),
            cell(''),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildAssessmentSection(int lectureUnits) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Assessment Details', style: _style(size: 9, bold: true)),
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Tuition Fees: Undergrad: $lectureUnits x 150/unit',
                    style: _style(size: 8),
                  ),
                  pw.Text(
                    'Laboratory Fees: (per ICT / Comp / IT schedule)',
                    style: _style(size: 8),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Miscellaneous Fees:', style: _style(size: 8, bold: true)),
                  pw.Text('Internet, Audio-Visual, Library, etc.', style: _style(size: 7.5)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPaymentSection() {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Schedule of Payments', style: _style(size: 9, bold: true)),
              pw.Text('Upon Enrollment:', style: _style(size: 8)),
              pw.Text('Balance Payable:', style: _style(size: 8)),
            ],
          ),
        ),
        pw.SizedBox(width: 80),
      ],
    );
  }

  pw.Widget _buildWithdrawalPolicy() {
    return pw.Text(
      'School Policy for Withdrawal: Refund percentages apply based on official '
      'university calendar (within 1st week 75%, 2nd week 50%, 3rd week 25%, '
      'thereafter none). See Registrar for full policy.',
      style: _style(size: 7),
    );
  }

  pw.Widget _buildSystemNote() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Note: This is a system generated report. Signature/Stamp is not required.',
          style: _style(size: 7.5, bold: true),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _sigLine('Noted by:', 'Adviser / College Dean'),
            _sigLine('Approved by:', 'University Registrar'),
          ],
        ),
      ],
    );
  }

  pw.Widget _sigLine(String title, String role) {
    return pw.SizedBox(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: _style(size: 8)),
          pw.SizedBox(height: 18),
          pw.Container(width: 120, height: 0.5, color: PdfColors.black),
          pw.SizedBox(height: 2),
          pw.Text(role, style: _style(size: 8)),
        ],
      ),
    );
  }
}
