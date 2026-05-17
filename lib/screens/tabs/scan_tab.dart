import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:lnu_app_class_locator/navigation/home_tabs.dart';
import 'package:lnu_app_class_locator/screens/campus_buildings_screen.dart';
import 'package:lnu_app_class_locator/services/eslip_ocr_service.dart';
import 'package:lnu_app_class_locator/state/app_repository.dart';
import 'package:lnu_app_class_locator/utils/eslip_ocr_parser.dart';
import 'package:lnu_app_class_locator/widgets/schedule_class_card.dart';

enum _ExtractorMenu { dashboard, schedule, buildings }

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

      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      await _showEslipImportSheet(repo, outcome, rawCharacterCount: raw.trim().length);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read the image: $e')),
        );
      }
    }
  }

  Future<void> _showEslipImportSheet(
    AppRepository repo,
    EslipParseOutcome outcome, {
    int rawCharacterCount = 0,
  }) async {
    final sel = List<bool>.filled(outcome.classes.length, true);
    var replaceSchedule = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final selectedCount = sel.where((x) => x).length;
            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.42,
              maxChildSize: 0.94,
              expand: false,
              builder: (_, scroll) => ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Material(
                  color: scheme.surface,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, color: scheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Schedule extractor',
                                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                      if (outcome.classes.length <= 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.tertiaryContainer.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                outcome.classes.isEmpty
                                    ? (rawCharacterCount > 60
                                        ? 'Text was read but no class rows matched. Photograph the enrolment table flat, include all CODE/SUBJECT/SCHEDULE rows, then scan again.'
                                        : 'No subjects found. Capture the full enrolment table (all rows) in good lighting, then scan again.')
                                    : 'Only 1 subject detected. Include the whole class table in the photo (usually 10–12 rows), then scan again.',
                                style: TextStyle(
                                  color: scheme.onTertiaryContainer,
                                  height: 1.35,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (outcome.warnings.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 88),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.errorContainer.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  outcome.warnings.length <= 3
                                      ? outcome.warnings.join('\n')
                                      : '${outcome.warnings.take(3).join('\n')}\n… and ${outcome.warnings.length - 3} more',
                                  style: TextStyle(
                                    color: scheme.onErrorContainer,
                                    height: 1.35,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        title: const Text('Replace current schedule'),
                        subtitle: const Text('Clears saved classes first'),
                        value: replaceSchedule,
                        onChanged: (v) => setSt(() => replaceSchedule = v),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              outcome.classes.length == 1
                                  ? '1 class detected'
                                  : '${outcome.classes.length} classes detected',
                              style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => setSt(() {
                                for (var i = 0; i < sel.length; i++) {
                                  sel[i] = true;
                                }
                              }),
                              child: const Text('Select all'),
                            ),
                            TextButton(
                              onPressed: () => setSt(() {
                                for (var i = 0; i < sel.length; i++) {
                                  sel[i] = false;
                                }
                              }),
                              child: const Text('Clear all'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: outcome.classes.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'No classes detected — try a clearer, well-lit photo.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scroll,
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                itemCount: outcome.classes.length,
                                itemBuilder: (_, i) {
                                  final c = outcome.classes[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _EslipClassPreviewCard(
                                      item: c,
                                      selected: sel[i],
                                      onToggle: (checked) => setSt(() => sel[i] = checked),
                                    ),
                                  );
                                },
                              ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: FilledButton(
                            onPressed: outcome.classes.isEmpty
                                ? null
                                : () async {
                              final toImport = <EslipClassRow>[];
                              for (var i = 0; i < outcome.classes.length; i++) {
                                if (sel[i]) toImport.add(outcome.classes[i]);
                              }
                              if (toImport.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Select at least one class to import.')),
                                );
                                return;
                              }
                              try {
                                if (replaceSchedule) {
                                  await repo.clearScheduleSlots();
                                }
                                final p = outcome.profile;
                                if (p.studentId != null ||
                                    p.fullName != null ||
                                    p.college != null ||
                                    p.course != null ||
                                    p.section != null) {
                                  await repo.saveProfile(
                                    studentId: p.studentId,
                                    fullName: p.fullName,
                                    college: p.college,
                                    course: p.course,
                                    section: p.section,
                                  );
                                }
                                final selected = toImport.length;
                                final imported =
                                    await repo.importEslipParsedClasses(toImport);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  final parts = <String>[];
                                  if (replaceSchedule) {
                                    parts.add('schedule replaced');
                                  }
                                  if (imported == selected) {
                                    parts.add(
                                      imported == 1
                                          ? '1 class saved'
                                          : '$imported classes saved',
                                    );
                                  } else {
                                    parts.add('$imported of $selected classes saved');
                                  }
                                  if (imported < outcome.classes.length &&
                                      selected == outcome.classes.length) {
                                    parts.add('rescan if subjects are missing');
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(parts.join(' · ')),
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                  if (imported > 0) {
                                    widget.onOpenTab(HomeTabs.schedule);
                                  }
                                }
                              } on FormatException catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              selectedCount == outcome.classes.length
                                  ? (selectedCount == 1
                                      ? 'Import all 1 class'
                                      : 'Import all $selectedCount classes')
                                  : (selectedCount == 1
                                      ? 'Add 1 class'
                                      : 'Add $selectedCount classes'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
                            case _ExtractorMenu.buildings:
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(builder: (_) => const CampusBuildingsScreen()),
                              );
                              break;
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: _ExtractorMenu.dashboard, child: Text('Dashboard')),
                          const PopupMenuItem(value: _ExtractorMenu.schedule, child: Text('Schedule')),
                          const PopupMenuDivider(),
                          const PopupMenuItem(value: _ExtractorMenu.buildings, child: Text('Campus buildings')),
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
                            '• Extractor hides the bottom bar — menu (top right): Dashboard, Schedule, Campus buildings.\n'
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

class _EslipClassPreviewCard extends StatelessWidget {
  const _EslipClassPreviewCard({
    required this.item,
    required this.selected,
    required this.onToggle,
  });

  final EslipClassRow item;
  final bool selected;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return ScheduleClassCard.fromEslip(
      item: item,
      selected: selected,
      onTap: () => onToggle(!selected),
      margin: EdgeInsets.zero,
      leading: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: selected,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (v) => onToggle(v ?? false),
          ),
        ),
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
