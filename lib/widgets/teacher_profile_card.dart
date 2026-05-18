import 'dart:io';

import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../screens/teacher_profile_screen.dart';

class TeacherProfileCard extends StatelessWidget {
  const TeacherProfileCard({
    super.key,
    required this.teacher,
    this.heroTag,
  });

  final Teacher teacher;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = teacher.name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    Widget avatar;
    if (teacher.profilePhotoPath != null &&
        File(teacher.profilePhotoPath!).existsSync()) {
      avatar = CircleAvatar(
        radius: 28,
        backgroundImage: FileImage(File(teacher.profilePhotoPath!)),
      );
    } else {
      avatar = CircleAvatar(
        radius: 28,
        backgroundColor: scheme.primaryContainer,
        child: Text(initials, style: TextStyle(color: scheme.onPrimaryContainer)),
      );
    }

    final nameWidget = heroTag != null
        ? Hero(tag: heroTag!, child: Material(color: Colors.transparent, child: Text(teacher.name)))
        : Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.w700));

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => TeacherProfileScreen(teacherId: teacher.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        nameWidget,
                        if (teacher.position != null && teacher.position!.isNotEmpty)
                          Chip(
                            label: Text(teacher.position!),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (teacher.department != null || teacher.college != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    [teacher.department, teacher.college]
                        .whereType<String>()
                        .where((e) => e.isNotEmpty)
                        .join(' · '),
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              if (teacher.officeHours != null && teacher.officeHours!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Chip(
                    avatar: const Icon(Icons.schedule, size: 16),
                    label: Text('Office: ${teacher.officeHours}'),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => TeacherProfileScreen(teacherId: teacher.id),
                    ),
                  ),
                  child: const Text('View full profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
