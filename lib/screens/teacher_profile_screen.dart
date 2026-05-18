import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/teacher.dart';
import '../state/app_repository.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  Teacher? _teacher;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<AppRepository>();
    final rows = await repo.listTeachers();
    Teacher? found;
    for (final t in rows) {
      if (t.id == widget.teacherId) {
        found = t;
        break;
      }
    }
    setState(() {
      _teacher = found;
      _loading = false;
    });
  }

  void _openEdit() {
    final t = _teacher;
    if (t == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TeacherEditSheet(
        teacher: t,
        onSave: (updated) async {
          await context.read<AppRepository>().updateTeacher(updated);
          if (mounted) {
            setState(() => _teacher = updated);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final t = _teacher;
    if (t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Teacher not found')),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Hero(
                tag: 'teacher_${t.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(t.name),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.primaryContainer],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: _avatar(t, 56),
                  ),
                  if (t.position != null) ...[
                    const SizedBox(height: 12),
                    Center(child: Chip(label: Text(t.position!))),
                  ],
                  _info('Department', t.department),
                  _info('College', t.college),
                  _info('Email', t.email),
                  _info('Contact', t.contactNumber),
                  _info('Office', t.officeRoom),
                  _info('Office hours', t.officeHours),
                  _info('Years of service', t.yearsOfService?.toString()),
                  if (t.bio != null && t.bio!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Bio', style: Theme.of(context).textTheme.titleSmall),
                    Text(t.bio!),
                  ],
                  if (t.subjectsTaught.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Subjects', style: Theme.of(context).textTheme.titleSmall),
                    Wrap(
                      spacing: 8,
                      children: t.subjectsTaught
                          .map((s) => Chip(label: Text(s)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEdit,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _avatar(Teacher t, double radius) {
    if (t.profilePhotoPath != null && File(t.profilePhotoPath!).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(t.profilePhotoPath!)),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: Text(t.name.isNotEmpty ? t.name[0] : '?'),
    );
  }

  Widget _info(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _TeacherEditSheet extends StatefulWidget {
  const _TeacherEditSheet({required this.teacher, required this.onSave});

  final Teacher teacher;
  final ValueChanged<Teacher> onSave;

  @override
  State<_TeacherEditSheet> createState() => _TeacherEditSheetState();
}

class _TeacherEditSheetState extends State<_TeacherEditSheet> {
  late final TextEditingController _position;
  late final TextEditingController _department;
  late final TextEditingController _email;
  late final TextEditingController _contact;
  late final TextEditingController _officeHours;
  late final TextEditingController _officeRoom;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    _position = TextEditingController(text: t.position ?? '');
    _department = TextEditingController(text: t.department ?? '');
    _email = TextEditingController(text: t.email ?? '');
    _contact = TextEditingController(text: t.contactNumber ?? '');
    _officeHours = TextEditingController(text: t.officeHours ?? '');
    _officeRoom = TextEditingController(text: t.officeRoom ?? '');
    _bio = TextEditingController(text: t.bio ?? '');
  }

  @override
  void dispose() {
    _position.dispose();
    _department.dispose();
    _email.dispose();
    _contact.dispose();
    _officeHours.dispose();
    _officeRoom.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
              _tf('Position', _position),
              _tf('Department', _department),
              _tf('Email', _email),
              _tf('Contact', _contact),
              _tf('Office hours', _officeHours),
              _tf('Office room', _officeRoom),
              _tf('Bio', _bio, maxLines: 3),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  widget.onSave(
                    widget.teacher.copyWith(
                      position: _position.text.trim(),
                      department: _department.text.trim(),
                      email: _email.text.trim(),
                      contactNumber: _contact.text.trim(),
                      officeHours: _officeHours.text.trim(),
                      officeRoom: _officeRoom.text.trim(),
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

  Widget _tf(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
