import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/validated_eslip_row.dart';
import '../state/app_repository.dart';
import '../utils/debug_agent_log.dart';
import '../utils/eslip_ocr_parser.dart';
import '../widgets/eslip_table_widget.dart';

class EslipPrintableView extends StatefulWidget {
  const EslipPrintableView({
    super.key,
    required this.profile,
    required this.rows,
  });

  final EslipParsedProfile profile;
  final List<ValidatedEslipRow> rows;

  @override
  State<EslipPrintableView> createState() => _EslipPrintableViewState();
}

class _EslipPrintableViewState extends State<EslipPrintableView> {
  @override
  void initState() {
    super.initState();
    // #region agent log
    agentDebugLog(
      location: 'eslip_printable_view.dart:initState',
      message: 'printable_open',
      hypothesisId: 'H3',
      data: {
        'rowCount': widget.rows.length,
        'hasProfileName': (widget.profile.fullName ?? '').isNotEmpty,
      },
    );
    // #endregion
  }

  Future<void> _exportPdf(BuildContext context) async {
    final profile = widget.profile;
    final rows = widget.rows;
    final doc = pw.Document();
    var totalUnits = 0;
    var totalLab = 0;
    for (final r in rows) {
      totalUnits += int.tryParse(r.units) ?? 0;
      totalLab += int.tryParse(r.lab) ?? 0;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (ctx) => [
          pw.Text(
            'LEYTE NORMAL UNIVERSITY',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${profile.semester ?? 'First Semester'} ${profile.academicYear ?? ''}',
          ),
          pw.Text('ID: ${profile.studentId ?? ''}  Name: ${profile.fullName ?? ''}'),
          pw.Text('College: ${profile.college ?? ''}  Course: ${profile.course ?? ''}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'CODE',
              'SUBJECT',
              'DESCRIPTION',
              'UNITS',
              'LAB',
              'SCHEDULE',
              'SEC',
              'INSTRUCTOR',
            ],
            data: [
              ...rows.map(
                (r) => [
                  r.enrollmentCode ?? '',
                  r.subjectCode,
                  r.description,
                  r.units,
                  r.lab,
                  r.scheduleRaw,
                  r.section,
                  r.instructor,
                ],
              ),
              [
                'Total Units: $totalUnits $totalLab',
                '',
                '',
                '',
                '',
                '',
                '',
                '',
              ],
            ],
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    // #region agent log
    agentDebugLog(
      location: 'eslip_printable_view.dart:build',
      message: 'printable_build',
      hypothesisId: 'H2',
      data: {'rowCount': widget.rows.length},
      runId: 'post-fix',
    );
    // #endregion

    final preview = EslipPreviewCard(
      profile: widget.profile,
      rows: widget.rows,
    );

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('E-slip preview'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
      ),
      body: preview,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _exportPdf(context),
        icon: const Icon(Icons.print),
        label: const Text('Print / Export PDF'),
      ),
    );
  }
}

/// Scrollable on-screen e-slip preview before printing.
class EslipPreviewCard extends StatelessWidget {
  const EslipPreviewCard({
    super.key,
    required this.profile,
    required this.rows,
  });

  final EslipParsedProfile profile;
  final List<ValidatedEslipRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No schedule rows to preview. Scan your e-slip first.'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: EslipTableWidget(profile: profile, rows: rows),
        ),
      ),
    );
  }
}

/// Opens printable view from saved schedule + student profile.
Future<void> openPrintableFromSaved(BuildContext context) async {
  // #region agent log
  agentDebugLog(
    location: 'eslip_printable_view.dart:openPrintableFromSaved',
    message: 'open_saved_start',
    hypothesisId: 'H4',
    runId: 'post-fix',
  );
  // #endregion

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final repo = context.read<AppRepository>();
  try {
  final student = await repo.getStudentProfile();
  final classes = await repo.allDistinctClasses();
  // #region agent log
  agentDebugLog(
    location: 'eslip_printable_view.dart:openPrintableFromSaved',
    message: 'open_saved_data',
    hypothesisId: 'H4',
    data: {'classCount': classes.length},
  );
  // #endregion
  final profile = EslipParsedProfile(
    studentId: student.idNumber,
    fullName: student.name,
    college: student.college,
    course: student.course,
    section: student.section,
    year: student.year,
    semester: student.semester,
    academicYear: student.academicYear,
    formNumber: student.formNumber,
  );
  final rows = classes
      .map(
        (p) => ValidatedEslipRow(
          subjectCode: p.subjectCode,
          description: p.subjectTitle,
          units: '',
          lab: '',
          scheduleRaw:
              '${p.startTime} – ${p.endTime} ${p.dayToken} ${p.roomCode}',
          section: '',
          instructor: p.instructor,
          parsed: p,
          confidence: RowConfidenceLevel.high,
          confidenceScore: 1,
          fieldIssues: const [],
        ),
      )
      .toList();

  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

  if (!context.mounted) return;
  // #region agent log
  agentDebugLog(
    location: 'eslip_printable_view.dart:openPrintableFromSaved',
    message: 'open_saved_push',
    hypothesisId: 'H4',
    runId: 'post-fix',
    data: {'rowCount': rows.length},
  );
  // #endregion
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => EslipPrintableView(profile: profile, rows: rows),
    ),
  );
  } catch (e) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    // #region agent log
    agentDebugLog(
      location: 'eslip_printable_view.dart:openPrintableFromSaved',
      message: 'open_saved_error',
      hypothesisId: 'H4',
      runId: 'post-fix',
      data: {'error': e.toString()},
    );
    // #endregion
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open preview: $e')),
      );
    }
  }
}
