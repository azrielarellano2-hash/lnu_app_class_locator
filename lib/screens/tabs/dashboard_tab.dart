import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/home_tabs.dart';
import '../../state/app_repository.dart';
import '../../widgets/schedule_class_card.dart';
import '../../widgets/schedule_detail_sheet.dart';
import '../../widgets/student_green_header.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.onOpenTab});

  final HomeTabSelectedCallback onOpenTab;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  DashboardSummary? _summary;
  List<ScheduleSlot> _today = [];
  bool _loading = true;
  AppRepository? _repo;
  Timer? _debounce;

  String _greetingTailName(UserProfile? user) {
    final raw = user?.fullName?.trim();
    if (raw == null || raw.isEmpty) return '';
    final parts = raw.split(',');
    if (parts.length >= 2) {
      final right = parts.last.trim();
      if (right.isNotEmpty) return right.split(RegExp(r'\s+')).first.toUpperCase();
    }
    return raw.split(RegExp(r'\s+')).first.toUpperCase();
  }

  String _greetingWord() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _greetingLine(UserProfile? user) {
    final name = _greetingTailName(user);
    final tail = name.isEmpty ? '' : ', $name';
    return '${_greetingWord()}$tail!';
  }

  Future<void> _load(AppRepository repo, {bool showLoader = true}) async {
    if (showLoader) setState(() => _loading = true);
    try {
      final summary = await repo.dashboardSummary();
      final today = await repo.scheduleToday();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _today = today;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmReset(AppRepository repo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset for new e-slip'),
        content: const Text(
          'Clear all saved classes and profile on this device? You can then scan and import another e-slip.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await repo.resetEslip();
    await _load(repo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule and profile cleared.')),
    );
    widget.onOpenTab(HomeTabs.scan);
  }

  void _onRepoChanged() {
    final r = _repo;
    if (r == null || !mounted) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (!mounted || _repo == null) return;
      _load(_repo!, showLoader: _summary == null);
    });
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
    _debounce?.cancel();
    _repo?.removeListener(_onRepoChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final user = repo.profile;
    final summary = _summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Column(
        children: [
          StudentGreenHeader(
            dashboardHeader: true,
            title: 'Class schedule',
            leading: const Icon(Icons.school_outlined, color: Colors.white, size: 28),
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingLine(user),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                if (summary != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    summary.greetingDateLocal,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF86EFAC),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                if (_loading && summary == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else if (summary != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: HeaderStatCard(
                          label: 'Subjects',
                          value: '${summary.subjectCount}',
                          onTap: () => widget.onOpenTab(HomeTabs.schedule),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HeaderStatCard(
                          label: 'Free today',
                          value: '${summary.freeHoursToday.toStringAsFixed(1)} h',
                          onTap: () => widget.onOpenTab(HomeTabs.schedule),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(repo, showLoader: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Today's classes",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => widget.onOpenTab(HomeTabs.schedule),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open schedule'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_today.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No classes scheduled for today.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
                    ..._today.map(
                      (s) => ScheduleCard.fromSlot(
                        slot: s,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Color(0xFF1B5E20),
                            size: 22,
                          ),
                        ),
                        onTap: () => showScheduleDetailSheet(
                          context,
                          slot: s,
                          heroTag: 'subject_${s.id}',
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Import a new e-slip',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Clears your saved schedule and profile on this device.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _confirmReset(repo),
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Reset & scan again'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B5E20),
                            side: BorderSide(
                              color: const Color(0xFF1B5E20).withValues(alpha: 0.45),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
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
