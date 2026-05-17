import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/formatters.dart';

/// Bottom sheet with full subject description and class details.
void showScheduleClassDetail(BuildContext context, ScheduleSlot slot) {
  final scheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final code = slot.subjectName.trim();
  final title = slot.subjectTitle?.trim();
  final headline = (title != null && title.isNotEmpty)
      ? title
      : (code.isNotEmpty ? code : 'Class');
  final instructor = sanitizeInstructorForDisplay(slot.instructorName);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.28,
      maxChildSize: 0.75,
      expand: false,
      builder: (_, scroll) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: scheme.surface,
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
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
              const SizedBox(height: 20),
              Text(
                headline,
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (title != null && title.isNotEmpty && code.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  code,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _DetailRow(
                icon: Icons.access_time,
                label: 'Time',
                value: formatTimeRange(slot.startTime, slot.endTime),
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Day',
                value: slot.dayPattern != null && slot.dayPattern!.isNotEmpty
                    ? formatReadableDayPattern(slot.dayPattern!)
                    : formatReadableWeekday(slot.dayOfWeek),
              ),
              _DetailRow(
                icon: Icons.meeting_room_outlined,
                label: 'Room',
                value: slot.roomCode,
              ),
              if (instructor != null)
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Instructor',
                  value: instructor,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
