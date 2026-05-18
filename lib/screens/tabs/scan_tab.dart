import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:lnu_app_class_locator/navigation/home_tabs.dart';
import 'package:lnu_app_class_locator/services/eslip_ocr_service.dart';
import 'package:lnu_app_class_locator/state/app_repository.dart';
import 'package:lnu_app_class_locator/utils/eslip_ocr_parser.dart';
import 'package:lnu_app_class_locator/models/validated_eslip_row.dart';
import 'package:lnu_app_class_locator/screens/eslip_printable_view.dart';
import 'package:lnu_app_class_locator/screens/eslip_review_screen.dart';
import 'package:lnu_app_class_locator/utils/debug_agent_log.dart';

enum _ExtractorMenu { dashboard, schedule }

class ScanTab extends StatefulWidget {
  const ScanTab({super.key, required this.onOpenTab});

  /// Switch main tabs when bottom navigation is hidden on this screen.
  final HomeTabSelectedCallback onOpenTab;

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  static const _deepForest = Color(0xFF06180E);
  static const _leafMid = Color(0xFF1B5E20);
  static const _leafBright = Color(0xFF43A047);
  static const _mist = Color(0xFFE8F5E9);

  Future<void> _scanEslip(AppRepository repo) async {
    if (!EslipOcrService.isSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-slip scanning runs on Android or iOS devices.')),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSourceSheet(theme: Theme.of(ctx)),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 88);
    if (picked == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(c).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12))],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                SizedBox(width: 18),
                Text('Reading e-slip…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final raw = await EslipOcrService().recognizeFromFilePath(picked.path);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (raw.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No text detected. Use a sharper photo with the full enrolment table in frame.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final outcome = parseEslipOcrText(raw);
      if (!mounted) return;

      if (outcome.validatedRows.isEmpty && outcome.classes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                raw.trim().length > 60
                    ? 'Text was read but no class rows matched. Include the full enrolment table.'
                    : 'No subjects found. Capture the full table in good lighting.',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final result = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) => EslipReviewScreen(outcome: outcome),
        ),
      );
      // #region agent log
      agentDebugLog(
        location: 'scan_tab.dart:_scanEslip',
        message: 'review_returned',
        hypothesisId: 'H1',
        data: {
          'resultType': result?.runtimeType.toString() ?? 'null',
          'mounted': mounted,
        },
      );
      // #endregion
      if (!mounted || result is! Map) return;
      final imported = result['imported'] as int? ?? 0;
      final profile = result['profile'] as EslipParsedProfile?;
      List<ValidatedEslipRow>? rows;
      final rowsRaw = result['rows'];
      if (rowsRaw is List<ValidatedEslipRow>) {
        rows = rowsRaw;
      } else if (rowsRaw is List) {
        rows = rowsRaw.whereType<ValidatedEslipRow>().toList();
      }
      // #region agent log
      agentDebugLog(
        location: 'scan_tab.dart:_scanEslip',
        message: 'parsed_review_result',
        hypothesisId: 'H1',
        runId: 'post-fix',
        data: {
          'imported': imported,
          'rowCount': rows?.length ?? 0,
          'hasProfile': profile != null,
        },
      );
      // #endregion
      if (imported > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$imported classes saved')),
        );
        final printableRows = rows;
        if (profile != null &&
            printableRows != null &&
            printableRows.isNotEmpty) {
          final printableProfile = profile;
          // #region agent log
          agentDebugLog(
            location: 'scan_tab.dart:_scanEslip',
            message: 'push_printable_from_scan',
            hypothesisId: 'H1',
            data: {'rowCount': printableRows.length},
          );
          // #endregion
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => EslipPrintableView(
                profile: printableProfile,
                rows: printableRows,
              ),
            ),
          );
        }
        widget.onOpenTab(HomeTabs.schedule);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read the image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _deepForest,
                  _leafMid,
                  _leafBright,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
            child: SizedBox.expand(),
          ),
          Positioned(
            top: -60,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -30,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _mist.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'LNU SmartPath',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Schedule extractor',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'LNU enrolment form — SUBJECT, DESCRIPTION, SCHEDULE, INSTRUCTOR',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<_ExtractorMenu>(
                        tooltip: 'Menu',
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                        ),
                        offset: const Offset(0, 48),
                        color: Theme.of(context).colorScheme.surface,
                        onSelected: (action) {
                          switch (action) {
                            case _ExtractorMenu.dashboard:
                              widget.onOpenTab(HomeTabs.dashboard);
                              break;
                            case _ExtractorMenu.schedule:
                              widget.onOpenTab(HomeTabs.schedule);
                              break;
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: _ExtractorMenu.dashboard, child: Text('Dashboard')),
                          const PopupMenuItem(value: _ExtractorMenu.schedule, child: Text('Schedule')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Color(0x28000000), blurRadius: 28, offset: Offset(0, 14)),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _scanEslip(repo),
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: const Text('Scan e-slip (OCR)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.white.withValues(alpha: 0.95), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Offline mode',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• No internet required.\n'
                            '• Schedule stays in a local database.\n'
                            '• Day codes match your slip: MTh, TF, W, SS, MWF, etc.\n'
                            '• Extractor hides the bottom bar — menu (top right): Dashboard, Schedule.\n'
                            '• Descriptions are capped per row so OCR noise from other columns is reduced.\n'
                            '• Tip: photograph the table flat, in good light.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.45,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: scheme.surface,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.photo_library_outlined, color: scheme.onPrimaryContainer),
                  ),
                  title: const Text('Gallery'),
                  subtitle: const Text('Existing photo of your e-slip'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    child: Icon(Icons.photo_camera_outlined, color: scheme.onSecondaryContainer),
                  ),
                  title: const Text('Camera'),
                  subtitle: const Text('Capture the form now'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
