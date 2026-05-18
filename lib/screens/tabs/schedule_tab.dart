import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../models/schedule_item.dart';
import '../../state/app_repository.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/schedule_detail_sheet.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/weekly_schedule_grid.dart';
import '../eslip_printable_view.dart';
import '../student_profile_screen.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  WeeklySchedule? _weekly;
  DateTime _selected = DateTime.now();
  bool _loading = true;
  AppRepository? _repo;
  Timer? _reloadDebounce;
  Map<String, String> _customLabels = {};
  bool _gridView = true;

  Future<void> _load(AppRepository repo, {bool showLoader = true}) async {
    if (showLoader) setState(() => _loading = true);
    try {
      final monday = mondayOfWeekContaining(_selected);
      final data = await repo.scheduleWeekly(weekStart: isoDate(monday));
      final items = await repo.listAllScheduleItems();
      final labels = <String, String>{};
      for (final i in items) {
        if (i.type == ScheduleItemType.customLabel && i.colorTag != null) {
          labels[i.subjectId] = i.colorTag!;
        }
      }
      if (!mounted) return;
      setState(() {
        _weekly = data;
        _customLabels = labels;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onRepoChanged() {
    final r = _repo;
    if (r == null || !mounted) return;
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 100), () {
      if (!mounted || _repo == null) return;
      _load(_repo!, showLoader: _weekly == null);
    });
  }

  WeeklyDay? _dayForSelected() {
    final w = _weekly;
    if (w == null) return null;
    final key = isoDate(DateTime(_selected.year, _selected.month, _selected.day));
    for (final d in w.days) {
      if (d.dateIso.startsWith(key)) return d;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final r = context.read<AppRepository>();
      _repo = r;
      r.addListener(_onRepoChanged);
      _load(r);
    });
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _repo?.removeListener(_onRepoChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final day = _dayForSelected();
    final slots = day?.slots ?? [];
    final hasAnyClass = _weekly?.days.any((d) => d.slots.isNotEmpty) ?? false;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _load(repo, showLoader: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 16,
                  20,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Weekly schedule',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Student profile',
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => const StudentProfileScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.person_outline, color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      'Tap any class block for details',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: hasAnyClass
                              ? () => openPrintableFromSaved(context)
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Official schedule'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _gridView = !_gridView),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          icon: Icon(_gridView ? Icons.view_list : Icons.grid_view),
                          label: Text(_gridView ? 'List view' : 'Grid view'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_weekly != null)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 96,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: _weekly!.days.length,
                    itemBuilder: (context, i) {
                      final d = _weekly!.days[i];
                      final dt = DateTime.tryParse(d.dateIso) ?? DateTime.now();
                      final sel = isoDate(dt) ==
                          isoDate(DateTime(_selected.year, _selected.month, _selected.day));
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selected = dt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel ? Colors.green.shade700 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  d.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: sel ? Colors.white : Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${dt.day}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loading) ...[
                      const ShimmerBox(height: 320),
                      const SizedBox(height: 16),
                      const ShimmerBox(height: 80),
                    ] else if (!hasAnyClass)
                      EmptyState(
                        icon: Icons.calendar_month_outlined,
                        title: 'No schedule yet',
                        message:
                            'Scan your enrolment e-slip to build your weekly grid.',
                        actionLabel: 'Open extractor',
                        onAction: () {
                          DefaultTabController.of(context);
                        },
                      )
                    else if (_gridView && _weekly != null) ...[
                      Text(
                        'Time grid (Mon–Sat)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      WeeklyScheduleGrid(
                        week: _weekly!,
                        customLabels: _customLabels,
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      MaterialLocalizations.of(context).formatFullDate(
                        DateTime(_selected.year, _selected.month, _selected.day),
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (!_loading && slots.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No classes on this day.'),
                        ),
                      )
                    else if (!_loading)
                      ...slots.map(
                        (s) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => showScheduleDetailSheet(
                              context,
                              slot: s,
                              heroTag: 'subject_${s.id}',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.subjectName,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        Text(formatTimeRange(s.startTime, s.endTime)),
                                        Text(s.roomCode),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
