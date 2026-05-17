import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_repository.dart';
import '../../utils/formatters.dart';
import '../../utils/schedule_day_filter.dart';
import '../../widgets/schedule_class_card.dart';
import '../../widgets/schedule_class_detail_sheet.dart';

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

  Future<void> _load(AppRepository repo, {bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _loading = true);
    }
    try {
      final monday = mondayOfWeekContaining(_selected);
      final data = await repo.scheduleWeekly(weekStart: isoDate(monday));
      final savedTotal = (await repo.allDistinctClasses()).length;
      if (!mounted) return;
      final wd =
          DateTime(_selected.year, _selected.month, _selected.day).weekday -
              DateTime.monday;
      final daySlots =
          data.days.length > wd ? data.days[wd].slots : <ScheduleSlot>[];
      debugPrint(
        'Schedule: ${daySlots.length} on ${weekdayNames[wd.clamp(0, 6)]}, '
        '$savedTotal saved from e-slip',
      );
      setState(() => _weekly = data);
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
    final key =
        isoDate(DateTime(_selected.year, _selected.month, _selected.day));
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
                    const Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'LNU SmartPath',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Weekly schedule',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Updates when you add or scan classes',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    itemCount: _weekly!.days.length,
                    itemBuilder: (context, i) {
                      final d = _weekly!.days[i];
                      final dt =
                          DateTime.tryParse(d.dateIso) ?? DateTime.now();
                      final sel = isoDate(dt) ==
                          isoDate(DateTime(
                            _selected.year,
                            _selected.month,
                            _selected.day,
                          ));
                      final hasClasses = d.slots.isNotEmpty;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selected = dt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? Colors.green.shade700
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  d.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        sel ? Colors.white : Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${dt.day}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        sel ? Colors.white : Colors.black87,
                                  ),
                                ),
                                if (hasClasses)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color:
                                          sel ? Colors.white : Colors.green,
                                      shape: BoxShape.circle,
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
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            MaterialLocalizations.of(context).formatFullDate(
                              DateTime(
                                _selected.year,
                                _selected.month,
                                _selected.day,
                              ),
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (slots.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No classes for this day. Use Extractor to scan your full e-slip, '
                            'then tap Import all classes.',
                          ),
                        ),
                      )
                    else
                      ...slots.map(
                        (s) => ScheduleClassCard.fromSlot(
                          slot: s,
                          onTap: () => showScheduleClassDetail(context, s),
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
