import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../models/schedule_item.dart';
import '../models/teacher.dart';
import '../screens/schedule_items_screen.dart';
import '../state/app_repository.dart';
import '../utils/formatters.dart';
import '../utils/subject_color.dart';
import 'add_item_sheet.dart';
import 'teacher_profile_card.dart';

void showScheduleDetailSheet(
  BuildContext context, {
  required ScheduleSlot slot,
  String? heroTag,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ScheduleDetailSheet(slot: slot, heroTag: heroTag),
  );
}

class _ScheduleDetailSheet extends StatefulWidget {
  const _ScheduleDetailSheet({required this.slot, this.heroTag});

  final ScheduleSlot slot;
  final String? heroTag;

  @override
  State<_ScheduleDetailSheet> createState() => _ScheduleDetailSheetState();
}

class _ScheduleDetailSheetState extends State<_ScheduleDetailSheet> {
  Teacher? _teacher;
  List<ScheduleItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<AppRepository>();
    final ins = widget.slot.instructorName?.trim();
    Teacher? teacher;
    if (ins != null && ins.isNotEmpty) {
      teacher = await repo.getTeacherByName(ins);
      teacher ??= await repo.upsertTeacherFromInstructor(
        ins,
        subjectCode: widget.slot.subjectName,
      );
    }
    final items = await repo.listScheduleItemsForSubject(widget.slot.subjectName);
    if (mounted) {
      setState(() {
        _teacher = teacher;
        _items = items.where((i) => !i.isCompleted).take(8).toList();
        _loading = false;
      });
    }
  }

  void _addItem(ScheduleItemType type) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddItemSheet(
        subjectId: widget.slot.subjectName,
        type: type,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final scheme = Theme.of(context).colorScheme;
    final code = slot.subjectName;
    final title = slot.subjectTitle?.trim();
    final color = subjectBlockColor(code);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 1,
      expand: false,
      builder: (_, scroll) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          color: scheme.surface,
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.heroTag != null)
                    Hero(
                      tag: widget.heroTag!,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    )
                  else
                    Chip(label: Text(code)),
                  if (slot.section != null && slot.section!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Chip(label: Text(slot.section!)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title != null && title.isNotEmpty ? title : code,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '${formatTimeRange(slot.startTime, slot.endTime)} · ${slot.roomCode}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const Divider(height: 28),
              Text('Teacher profile', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_loading)
                const LinearProgressIndicator()
              else if (_teacher != null)
                TeacherProfileCard(
                  teacher: _teacher!,
                  heroTag: 'teacher_${_teacher!.id}',
                )
              else
                const Text('No instructor on file'),
              const SizedBox(height: 20),
              Text('Student actions', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _actionChip(Icons.quiz_outlined, 'Add quiz', () => _addItem(ScheduleItemType.quiz)),
                  _actionChip(Icons.notifications_outlined, 'Reminder', () => _addItem(ScheduleItemType.reminder)),
                  _actionChip(Icons.event_note, 'Activity', () => _addItem(ScheduleItemType.activity)),
                  _actionChip(Icons.note_alt_outlined, 'Note', () => _addItem(ScheduleItemType.note)),
                  _actionChip(Icons.label_outline, 'Label', () => _addItem(ScheduleItemType.customLabel)),
                  _actionChip(Icons.list, 'View all', () {
                    Navigator.pop(context);
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => ScheduleItemsScreen(
                          subjectId: slot.subjectName,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),
              Text('Upcoming', style: Theme.of(context).textTheme.titleSmall),
              if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No quizzes or reminders yet',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              else
                ..._items.map(
                  (i) => ListTile(
                    leading: Icon(_iconFor(i.type)),
                    title: Text(i.title),
                    subtitle: i.dueDate != null ? Text(i.dueDate!) : null,
                    dense: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  IconData _iconFor(ScheduleItemType t) {
    switch (t) {
      case ScheduleItemType.quiz:
        return Icons.quiz;
      case ScheduleItemType.reminder:
        return Icons.notifications;
      case ScheduleItemType.activity:
        return Icons.event;
      case ScheduleItemType.note:
        return Icons.note;
      case ScheduleItemType.customLabel:
        return Icons.label;
    }
  }
}
