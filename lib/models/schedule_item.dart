import 'dart:convert';

enum ScheduleItemType {
  quiz,
  reminder,
  activity,
  note,
  customLabel,
}

enum ScheduleItemPriority { low, medium, high }

ScheduleItemType scheduleItemTypeFromString(String s) {
  return ScheduleItemType.values.firstWhere(
    (e) => e.name == s,
    orElse: () => ScheduleItemType.note,
  );
}

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.subjectId,
    required this.type,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    this.priority = ScheduleItemPriority.medium,
    this.colorTag,
    this.attachmentPaths = const [],
    this.repeatRule,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subjectId;
  final ScheduleItemType type;
  final String title;
  final String? description;
  final String? dueDate;
  final String? dueTime;
  final bool isCompleted;
  final ScheduleItemPriority priority;
  final String? colorTag;
  final List<String> attachmentPaths;
  final String? repeatRule;
  final int createdAt;
  final int updatedAt;

  factory ScheduleItem.fromRow(Map<String, Object?> row) {
    List<String> paths = [];
    final ap = row['attachment_paths'] as String?;
    if (ap != null && ap.isNotEmpty) {
      paths = (jsonDecode(ap) as List<dynamic>).cast<String>();
    }
    return ScheduleItem(
      id: row['id'] as String,
      subjectId: row['subject_id'] as String,
      type: scheduleItemTypeFromString(row['type'] as String),
      title: row['title'] as String,
      description: row['description'] as String?,
      dueDate: row['due_date'] as String?,
      dueTime: row['due_time'] as String?,
      isCompleted: (row['is_completed'] as int) != 0,
      priority: ScheduleItemPriority.values.firstWhere(
        (e) => e.name == (row['priority'] as String? ?? 'medium'),
        orElse: () => ScheduleItemPriority.medium,
      ),
      colorTag: row['color_tag'] as String?,
      attachmentPaths: paths,
      repeatRule: row['repeat_rule'] as String?,
      createdAt: row['created_at'] as int,
      updatedAt: row['updated_at'] as int,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'subject_id': subjectId,
        'type': type.name,
        'title': title,
        'description': description,
        'due_date': dueDate,
        'due_time': dueTime,
        'is_completed': isCompleted ? 1 : 0,
        'priority': priority.name,
        'color_tag': colorTag,
        'attachment_paths': jsonEncode(attachmentPaths),
        'repeat_rule': repeatRule,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
