import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/parsed_schedule_display.dart';
import '../models/validated_eslip_row.dart';
import '../state/app_repository.dart';
import '../utils/debug_agent_log.dart';
import '../utils/eslip_ocr_parser.dart';
import '../utils/schedule_field_parser.dart';

Color _confidenceColor(RowConfidenceLevel level, ColorScheme scheme) {
  switch (level) {
    case RowConfidenceLevel.high:
      return Colors.green.shade600;
    case RowConfidenceLevel.medium:
      return Colors.amber.shade700;
    case RowConfidenceLevel.low:
      return scheme.error;
  }
}

class EslipReviewScreen extends StatefulWidget {
  const EslipReviewScreen({
    super.key,
    required this.outcome,
    this.replaceSchedule = true,
  });

  final EslipParseOutcome outcome;
  final bool replaceSchedule;

  @override
  State<EslipReviewScreen> createState() => _EslipReviewScreenState();
}

class _EslipReviewScreenState extends State<EslipReviewScreen> {
  late List<ValidatedEslipRow> _rows;
  late double _confidencePercent;

  @override
  void initState() {
    super.initState();
    _rows = List.from(widget.outcome.validatedRows);
    _confidencePercent = widget.outcome.overallConfidencePercent;
  }

  void _recalcConfidence() {
    if (_rows.isEmpty) {
      _confidencePercent = 0;
      return;
    }
    final sum = _rows.fold<double>(0, (a, r) => a + r.confidenceScore);
    setState(() => _confidencePercent = (sum / _rows.length * 100).roundToDouble());
  }

  void _updateRow(int index, ValidatedEslipRow row) {
    setState(() => _rows[index] = row);
    _recalcConfidence();
  }

  Future<void> _confirm() async {
    // #region agent log
    agentDebugLog(
      location: 'eslip_review_screen.dart:_confirm',
      message: 'confirm_start',
      hypothesisId: 'H1',
      data: {'rowCount': _rows.length, 'mounted': mounted},
    );
    // #endregion
    final repo = context.read<AppRepository>();
    final imported = await repo.confirmEslipImport(
      rows: _rows,
      profile: widget.outcome.profile,
      replaceSchedule: widget.replaceSchedule,
    );
    // #region agent log
    agentDebugLog(
      location: 'eslip_review_screen.dart:_confirm',
      message: 'confirm_import_done',
      hypothesisId: 'H5',
      data: {'imported': imported, 'mounted': mounted},
    );
    // #endregion
    if (!mounted) return;
    final nav = Navigator.of(context);
    // #region agent log
    agentDebugLog(
      location: 'eslip_review_screen.dart:_confirm',
      message: 'before_pop',
      hypothesisId: 'H1',
      data: {'canPop': nav.canPop()},
    );
    // #endregion
    nav.pop({'imported': imported, 'profile': widget.outcome.profile, 'rows': _rows});
    // #region agent log
    agentDebugLog(
      location: 'eslip_review_screen.dart:_confirm',
      message: 'after_pop',
      hypothesisId: 'H1',
      data: {'mounted': mounted},
    );
    // #endregion
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final confColor = _confidencePercent >= 85
        ? Colors.green.shade600
        : _confidencePercent >= 55
            ? Colors.amber.shade700
            : scheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review extracted schedule'),
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: confColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: confColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_outlined, color: confColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extraction confidence',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        '${_confidencePercent.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: confColor,
                            ),
                      ),
                      Text(
                        widget.outcome.headerDetected
                            ? 'Table header detected'
                            : 'Header not found — verify each row',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _rows.isEmpty
                ? const Center(child: Text('No rows to review'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _rows.length,
                    itemBuilder: (_, i) => _ReviewRowCard(
                      row: _rows[i],
                      onChanged: (r) => _updateRow(i, r),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _rows.isEmpty ? null : _confirm,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Confirm & save schedule'),
          ),
        ),
      ),
    );
  }
}

class _ReviewRowCard extends StatefulWidget {
  const _ReviewRowCard({required this.row, required this.onChanged});

  final ValidatedEslipRow row;
  final ValueChanged<ValidatedEslipRow> onChanged;

  @override
  State<_ReviewRowCard> createState() => _ReviewRowCardState();
}

class _ReviewRowCardState extends State<_ReviewRowCard> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.row);
  }

  @override
  void didUpdateWidget(covariant _ReviewRowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row != widget.row) {
      for (final c in _controllers.values) {
        c.dispose();
      }
      _initControllers(widget.row);
    }
  }

  void _initControllers(ValidatedEslipRow row) {
    _controllers = {
      'code': TextEditingController(text: row.enrollmentCode ?? ''),
      'subject': TextEditingController(text: row.subjectCode),
      'description': TextEditingController(text: row.description),
      'units': TextEditingController(text: row.units),
      'lab': TextEditingController(text: row.lab),
      'schedule': TextEditingController(text: row.scheduleRaw),
      'section': TextEditingController(text: row.section),
      'instructor': TextEditingController(text: row.instructor),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final scheme = Theme.of(context).colorScheme;
    final dotColor = _confidenceColor(row.confidence, scheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  row.subjectCode.isNotEmpty ? row.subjectCode : 'Row',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${(row.confidenceScore * 100).round()}%',
                  style: TextStyle(color: dotColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (row.fieldIssues.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  row.fieldIssues.join(' · '),
                  style: TextStyle(fontSize: 11, color: scheme.error),
                ),
              ),
            _field('Code', _controllers['code']!, (v) {
              widget.onChanged(row.copyWith(enrollmentCode: v));
            }),
            _field('Subject', _controllers['subject']!, (v) {
              widget.onChanged(_reparse(row.copyWith(subjectCode: v)));
            }),
            _field('Description', _controllers['description']!, (v) {
              widget.onChanged(_reparse(row.copyWith(description: v)));
            }),
            _field('Units', _controllers['units']!, (v) {
              widget.onChanged(row.copyWith(units: v));
            }),
            _field('Lab', _controllers['lab']!, (v) {
              widget.onChanged(row.copyWith(lab: v));
            }),
            _field('Schedule & room', _controllers['schedule']!, (v) {
              widget.onChanged(_reparse(row.copyWith(scheduleRaw: v)));
            }),
            _field('Section', _controllers['section']!, (v) {
              widget.onChanged(row.copyWith(section: v));
            }),
            _field('Instructor', _controllers['instructor']!, (v) {
              widget.onChanged(row.copyWith(instructor: v));
            }),
          ],
        ),
      ),
    );
  }

  ValidatedEslipRow _reparse(ValidatedEslipRow r) {
    final field = r.scheduleRaw.isNotEmpty
        ? parseScheduleField(r.scheduleRaw, log: false)
        : null;
    var score = 0.0;
    final issues = <String>[];
    if (r.subjectCode.isNotEmpty) score += 0.2;
    if (r.description.isNotEmpty) score += 0.15;
    if (field != null) {
      score += 0.45;
    } else if (r.scheduleRaw.isNotEmpty) {
      issues.add('Invalid schedule');
    }
    if (r.instructor.isNotEmpty) score += 0.1;
    if (r.section.isNotEmpty) score += 0.05;
    if (r.units.isNotEmpty) score += 0.05;

    ParsedScheduleDisplay? parsed = r.parsed;
    if (field != null) {
      parsed = ParsedScheduleDisplay(
        startTime: field.startTime,
        endTime: field.endTime,
        subjectCode: r.subjectCode,
        subjectTitle: r.description,
        subjectName: r.subjectCode,
        roomCode: field.roomCode,
        instructor: r.instructor,
        dayPattern: field.dayPattern,
        dayToken: field.dayToken,
        startTimeRaw: field.startTimeRaw,
        endTimeRaw: field.endTimeRaw,
      );
    }

    final level = score >= 0.85
        ? RowConfidenceLevel.high
        : score >= 0.55
            ? RowConfidenceLevel.medium
            : RowConfidenceLevel.low;

    return r.copyWith(
      parsed: parsed,
      confidence: level,
      confidenceScore: score.clamp(0, 1),
      fieldIssues: issues,
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        controller: controller,
        onChanged: onChanged,
      ),
    );
  }
}
