import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/slot_display_mapper.dart';

/// Compact schedule row (code, time, room, chevron) for the weekly list view.
class ScheduleCompactCard extends StatelessWidget {
  const ScheduleCompactCard({
    super.key,
    required this.slot,
    this.onTap,
  });

  final ScheduleSlot slot;
  final VoidCallback? onTap;

  static const _fill = Color(0xFFF1F8F2);

  @override
  Widget build(BuildContext context) {
    final parsed = parsedScheduleFromSlot(slot);
    final code = parsed.subjectCode.trim().isNotEmpty
        ? parsed.subjectCode
        : slot.subjectName;
    final time = parsed.cardTimeRange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _fill,
        elevation: 1,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (time.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                      if (slot.roomCode.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          slot.roomCode.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF616161),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
