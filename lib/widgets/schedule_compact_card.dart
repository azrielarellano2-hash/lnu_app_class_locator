import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final parsed = parsedScheduleFromSlot(slot);
    final code = parsed.subjectCode.trim().isNotEmpty
        ? parsed.subjectCode
        : slot.subjectName;
    final time = parsed.cardTimeRange;
    final room = slot.roomCode.trim();
    final timeRoom = [
      if (time.isNotEmpty) time,
      if (room.isNotEmpty) room,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x07000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.subjectAccent(code),
                        ),
                      ),
                      if (timeRoom.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          timeRoom,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
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
