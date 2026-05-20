import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/validated_eslip_row.dart';
import '../services/official_eslip_pdf_builder.dart';
import '../state/app_repository.dart';
import '../utils/eslip_ocr_parser.dart';
import '../utils/eslip_printable_rows.dart';
import '../widgets/eslip_table_widget.dart';

class EslipPrintableView extends StatelessWidget {
  const EslipPrintableView({
    super.key,
    required this.profile,
    required this.rows,
  });

  final EslipParsedProfile profile;
  final List<ValidatedEslipRow> rows;

  Future<void> _exportPdf(BuildContext context) async {
    final sorted = List<ValidatedEslipRow>.from(rows);
    sortEslipRowsByCode(sorted);
    final bytes = await OfficialEslipPdfBuilder(
      profile: profile,
      rows: sorted,
    ).build();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Enrolment form preview'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
      ),
      body: EslipPreviewCard(profile: profile, rows: rows),
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
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: EslipTableWidget(profile: profile, rows: rows),
        ),
      ),
    );
  }
}

/// Opens printable view from saved schedule + student profile.
Future<void> openPrintableFromSaved(BuildContext context) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final repo = context.read<AppRepository>();
  try {
    final student = await repo.getStudentProfile();
    final slots = await repo.allScheduleSlots();
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
      enrolmentDate: null,
    );

    final rows = buildPrintableRowsFromSlots(
      slots,
      defaultSection: student.section,
    );

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (!context.mounted) return;

    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No classes saved yet. Scan your e-slip first.')),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EslipPrintableView(profile: profile, rows: rows),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open preview: $e')),
      );
    }
  }
}
