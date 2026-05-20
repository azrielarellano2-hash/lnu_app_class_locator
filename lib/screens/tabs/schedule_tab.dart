import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_repository.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/schedule_compact_card.dart';
import '../../widgets/schedule_detail_sheet.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/student_green_header.dart';
import '../../widgets/week_day_strip.dart';
import '../eslip_printable_view.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  WeeklySchedule? _weekly;
  bool _loading = true;
  int _selectedDayIndex = 0;
  AppRepository? _repo;
  Timer? _reloadDebounce;

  int _todayWeekdayIndex() {
    final w = DateTime.now().weekday - DateTime.monday;
    return w.clamp(0, 5);
  }

  Future<void> _load(AppRepository repo, {bool showLoader = true}) async {
    if (showLoader) setState(() => _loading = true);
    try {
      final monday = mondayOfWeekContaining(DateTime.now());
      final data = await repo.scheduleWeekly(weekStart: isoDate(monday));
      if (!mounted) return;
      setState(() {
        _weekly = data;
        _selectedDayIndex = _todayWeekdayIndex();
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

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = _todayWeekdayIndex();
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
    final hasAnyClass = _weekly?.days.any((d) => d.slots.isNotEmpty) ?? false;
    final week = _weekly;
    final selectedDay = week != null && _selectedDayIndex < week.days.length
        ? week.days[_selectedDayIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Column(
        children: [
          StudentGreenHeader(
            title: 'Weekly schedule',
            subtitle: 'Tap any class block for details',
            bottom: HeaderPillButton(
              label: 'Official schedule',
              icon: Icons.print_outlined,
              onPressed: hasAnyClass ? () => openPrintableFromSaved(context) : null,
            ),
          ),
          if (_loading)
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerBox(height: 120),
              ),
            )
          else if (!hasAnyClass || week == null)
            const Expanded(
              child: Center(
                child: EmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: 'No schedule yet',
                  message: 'Scan your enrolment e-slip in the Extractor tab.',
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(repo, showLoader: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    const SizedBox(height: 8),
                    WeekDayStrip(
                      week: week,
                      selectedIndex: _selectedDayIndex,
                      onSelected: (i) => setState(() => _selectedDayIndex = i),
                    ),
                    if (selectedDay != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          WeekDayStrip.formatSelectedDateLabel(selectedDay),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ),
                      if (selectedDay.slots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                          child: Text(
                            'No classes on this day.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      else
                        ...selectedDay.slots.map(
                          (s) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ScheduleCompactCard(
                              slot: s,
                              onTap: () => showScheduleDetailSheet(
                                context,
                                slot: s,
                                heroTag: 'subject_${s.id}',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
