import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule_item.dart';
import '../services/notification_service.dart';
import '../state/app_repository.dart';

const _labelColors = [
  '#E53935',
  '#FB8C00',
  '#FDD835',
  '#43A047',
  '#1E88E5',
  '#8E24AA',
  '#6D4C41',
  '#546E7A',
];

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({
    super.key,
    required this.subjectId,
    required this.type,
    required this.onSaved,
    this.existing,
  });

  final String subjectId;
  final ScheduleItemType type;
  final VoidCallback onSaved;
  final ScheduleItem? existing;

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _notes;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  ScheduleItemPriority _priority = ScheduleItemPriority.medium;
  String _repeat = 'none';
  String? _colorTag;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _notes = TextEditingController();
    _colorTag = e?.colorTag;
    if (e?.dueDate != null) {
      _dueDate = DateTime.tryParse(e!.dueDate!);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _dueDate ?? DateTime.now(),
    );
    if (d != null) setState(() => _dueDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _dueTime = t);
  }

  Future<void> _save() async {
    final repo = context.read<AppRepository>();
    final now = DateTime.now().millisecondsSinceEpoch;
    final dueStr = _dueDate != null
        ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
        : null;
    final timeStr = _dueTime != null
        ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final item = ScheduleItem(
      id: widget.existing?.id ?? repo.newScheduleItem(
            subjectId: widget.subjectId,
            type: widget.type,
            title: _title.text.trim(),
          ).id,
      subjectId: widget.subjectId,
      type: widget.type,
      title: _title.text.trim().isEmpty ? 'Untitled' : _title.text.trim(),
      description: _description.text.trim().isEmpty ? _notes.text.trim() : _description.text.trim(),
      dueDate: dueStr,
      dueTime: timeStr,
      priority: _priority,
      colorTag: _colorTag,
      repeatRule: widget.type == ScheduleItemType.reminder ? _repeat : null,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    await repo.saveScheduleItem(item);

    if (widget.type == ScheduleItemType.reminder &&
        _dueDate != null &&
        widget.existing == null) {
      final when = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime?.hour ?? 9,
        _dueTime?.minute ?? 0,
      );
      await NotificationService.instance.scheduleReminder(
        notificationId: item.id.hashCode.abs() % 100000,
        title: item.title,
        body: item.description ?? 'Class reminder',
        when: when,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      expand: false,
      builder: (_, scroll) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            children: [
              Text(_sheetTitle, style: Theme.of(context).textTheme.titleLarge),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              if (widget.type == ScheduleItemType.quiz ||
                  widget.type == ScheduleItemType.activity) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _description,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: widget.type == ScheduleItemType.quiz
                        ? 'Coverage / topics'
                        : 'Description',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              if (widget.type == ScheduleItemType.note) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _description,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Note body',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (widget.type != ScheduleItemType.customLabel &&
                  widget.type != ScheduleItemType.note) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(onPressed: _pickDate, child: const Text('Date')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: _pickTime, child: const Text('Time')),
                  ],
                ),
              ],
              if (widget.type == ScheduleItemType.reminder) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _repeat,
                  decoration: const InputDecoration(labelText: 'Repeat'),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('None')),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: (v) => setState(() => _repeat = v ?? 'none'),
                ),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
              if (widget.type == ScheduleItemType.activity) ...[
                DropdownButtonFormField<ScheduleItemPriority>(
                  value: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: ScheduleItemPriority.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _priority = v ?? _priority),
                ),
              ],
              if (widget.type == ScheduleItemType.customLabel) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _labelColors.map((hex) {
                    final c = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                    final sel = _colorTag == hex;
                    return GestureDetector(
                      onTap: () => setState(() => _colorTag = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: sel ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }

  String get _sheetTitle {
    switch (widget.type) {
      case ScheduleItemType.quiz:
        return 'Add quiz';
      case ScheduleItemType.reminder:
        return 'Add reminder';
      case ScheduleItemType.activity:
        return 'Add activity';
      case ScheduleItemType.note:
        return 'Add note';
      case ScheduleItemType.customLabel:
        return 'Custom label';
    }
  }
}
