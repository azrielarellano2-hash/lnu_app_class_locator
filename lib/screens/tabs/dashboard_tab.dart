import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/home_tabs.dart';
import '../../state/app_repository.dart';
import '../../widgets/schedule_class_card.dart';
import '../../screens/student_profile_screen.dart';
import '../../widgets/schedule_detail_sheet.dart';

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
      if (right.isNotEmpty) return right.split(RegExp(r'\s+')).first;
    }
    return raw.split(RegExp(r'\s+')).first;
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
    if (showLoader) {
      setState(() => _loading = true);
    }
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

  void _onRepoChanged() {
    final r = _repo;
    if (r == null || !mounted) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (!mounted || _repo == null) return;
      _load(_repo!, showLoader: _summary == null);
    });
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
                    colors: [Color(0xFF0D2818), Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 16,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, color: Colors.white, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Class schedule',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
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
                    const SizedBox(height: 16),
                    Text(
                      _greetingLine(user),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    if (_summary != null)
                      Text(
                        _summary!.greetingDateLocal,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    const SizedBox(height: 16),
                    if (_loading && _summary == null)
                      const Center(child: CircularProgressIndicator(color: Colors.white))
                    else if (_summary != null)
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Subjects',
                              value: '${_summary!.subjectCount}',
                              onTap: () => widget.onOpenTab(HomeTabs.schedule),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              label: 'Free today',
                              value: '${_summary!.freeHoursToday.toStringAsFixed(1)} h',
                              onTap: () => widget.onOpenTab(HomeTabs.schedule),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Today's classes",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => widget.onOpenTab(HomeTabs.schedule),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open schedule'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_today.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('No classes for today.'),
                            const SizedBox(height: 8),
                            FilledButton.tonalIcon(
                              onPressed: () => widget.onOpenTab(HomeTabs.scan),
                              icon: const Icon(Icons.add),
                              label: const Text('Add or scan classes'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._today.map(
                      (s) => ScheduleClassCard.fromSlot(
                        slot: s,
                        onTap: () => showScheduleDetailSheet(
                          context,
                          slot: s,
                          heroTag: 'subject_${s.id}',
                        ),
                        leading: Icon(
                          Icons.schedule_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _confirmReset(repo),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clears your schedule and profile so you can scan a new e-slip.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
