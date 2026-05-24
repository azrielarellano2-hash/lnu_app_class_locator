import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_profile.dart';
import '../services/profile_photo_service.dart';
import '../state/app_repository.dart';
import '../theme/app_theme.dart';
import 'eslip_printable_view.dart';
import 'schedule_items_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  StudentProfile? _profile;
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<AppRepository>();
    final p = await repo.getStudentProfile();
    final stats = await repo.studentStats();
    if (mounted) {
      setState(() {
        _profile = p;
        _stats = stats;
        _loading = false;
      });
    }
  }

  void _edit() {
    final p = _profile;
    if (p == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudentEditSheet(
        profile: p,
        onSave: (updated) async {
          await context.read<AppRepository>().saveStudentProfile(updated);
          await _load();
        },
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (_profile == null) return;
    final source = await ProfilePhotoService.chooseImageSource(context);
    if (!mounted || source == null) return;
    final path = await const ProfilePhotoService().pickAndPersist(
      source: source,
      fileName: 'student_profile.jpg',
    );
    if (!mounted || path == null) return;
    final updated = _profile!.copyWith(profilePhotoPath: path);
    await context.read<AppRepository>().saveStudentProfile(updated);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = _profile!;
    final scheme = Theme.of(context).colorScheme;
    final initials = (p.name ?? 'S')
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    Widget avatar;
    if (p.profilePhotoPath != null && File(p.profilePhotoPath!).existsSync()) {
      avatar = CircleAvatar(
        radius: 48,
        backgroundImage: FileImage(File(p.profilePhotoPath!)),
      );
    } else {
      avatar = CircleAvatar(
        radius: 48,
        backgroundColor: scheme.primaryContainer,
        child: Text(initials, style: const TextStyle(fontSize: 28)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Student profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: avatar,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              p.name ?? 'Student',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (p.idNumber != null)
            Center(child: Text('ID ${p.idNumber}')),
          if (p.course != null)
            Center(
              child: Chip(label: Text(p.course!)),
            ),
          const SizedBox(height: 20),
          _row('College', p.college),
          _row('Year', p.year),
          _row('Section', p.section),
          _row('Semester', '${p.semester ?? ''} ${p.academicYear ?? ''}'.trim()),
          const Divider(height: 32),
          Text('Stats', style: Theme.of(context).textTheme.titleMedium),
          _row('Subjects', '${_stats['subjectCount'] ?? 0}'),
          _row('Lab subjects', '${_stats['labCount'] ?? 0}'),
          _row('Est. units', '${_stats['totalUnits'] ?? 0}'),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('View printable schedule'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openPrintableFromSaved(context),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('All reminders & activities'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const ScheduleItemsScreen(),
              ),
            ),
          ),
          if (p.bio != null && p.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Bio', style: Theme.of(context).textTheme.titleSmall),
            Text(p.bio!),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _edit,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StudentEditSheet extends StatefulWidget {
  const _StudentEditSheet({required this.profile, required this.onSave});

  final StudentProfile profile;
  final ValueChanged<StudentProfile> onSave;

  @override
  State<_StudentEditSheet> createState() => _StudentEditSheetState();
}

class _StudentEditSheetState extends State<_StudentEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _id;
  late final TextEditingController _college;
  late final TextEditingController _course;
  late final TextEditingController _year;
  late final TextEditingController _section;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.name ?? '');
    _id = TextEditingController(text: p.idNumber ?? '');
    _college = TextEditingController(text: p.college ?? '');
    _course = TextEditingController(text: p.course ?? '');
    _year = TextEditingController(text: p.year ?? '');
    _section = TextEditingController(text: p.section ?? '');
    _bio = TextEditingController(text: p.bio ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _college.dispose();
    _course.dispose();
    _year.dispose();
    _section.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (_, scroll) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            children: [
              Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
              _tf('Name', _name),
              _tf('ID number', _id),
              _tf('College', _college),
              _tf('Course', _course),
              _tf('Year', _year),
              _tf('Section', _section),
              _tf('Bio', _bio, lines: 3),
              FilledButton(
                onPressed: () {
                  widget.onSave(
                    widget.profile.copyWith(
                      name: _name.text.trim(),
                      idNumber: _id.text.trim(),
                      college: _college.text.trim(),
                      course: _course.text.trim(),
                      year: _year.text.trim(),
                      section: _section.text.trim(),
                      bio: _bio.text.trim(),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(String label, TextEditingController c, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: c,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
