import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/parsed_schedule_display.dart';
import '../theme/app_theme.dart';
import '../utils/eslip_ocr_parser.dart';
import '../utils/slot_display_mapper.dart';

/// University planner schedule card — five structured lines only.
class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.parsed,
    this.margin = const EdgeInsets.only(bottom: 14),
    this.leading,
    this.onTap,
    this.selected,
  });

  final ParsedScheduleDisplay parsed;
  final EdgeInsetsGeometry margin;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool? selected;

  factory ScheduleCard.fromClassRow({
    required EslipClassRow row,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 14),
    Widget? leading,
    VoidCallback? onTap,
    bool? selected,
  }) =>
      ScheduleCard(
        parsed: row.parsed,
        margin: margin,
        leading: leading,
        onTap: onTap,
        selected: selected,
      );

  factory ScheduleCard.fromEslip({
    required EslipClassRow item,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 14),
    Widget? leading,
    VoidCallback? onTap,
    bool? selected,
  }) =>
      ScheduleCard.fromClassRow(
        row: item,
        margin: margin,
        leading: leading,
        onTap: onTap,
        selected: selected,
      );

  factory ScheduleCard.fromSlot({
    required ScheduleSlot slot,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 14),
    Widget? leading,
    VoidCallback? onTap,
  }) =>
      ScheduleCard(
        parsed: parsedScheduleFromSlot(slot),
        margin: margin,
        leading: leading,
        onTap: onTap,
      );

  static const Color _cardFillSelected = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == true;
    final timeRange = parsed.cardTimeRange;
    final courseLine = parsed.cardCourseLine;
    final room = parsed.roomCode.trim();
    final instructorLine = parsed.cardInstructorLine;
    final days = parsed.dayPattern.trim();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (timeRange.isNotEmpty) ...[
          Text(
            timeRange,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.subjectAccent(parsed.subjectCode),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (courseLine.isNotEmpty) ...[
          Text(
            courseLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (room.isNotEmpty) ...[
          Text(
            room,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
        if (instructorLine.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            instructorLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
        if (days.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            days,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ],
    );

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: leading!,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: content),
        ],
      ),
    );

    final card = Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shadowColor: Colors.transparent,
      color: isSelected ? _cardFillSelected : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.35)
              : const Color(0xFFE5E7EB),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: body,
      ),
    );

    return Padding(
      padding: margin,
      child: card,
    );
  }
}

/// Backwards-compatible name used across the app.
typedef ScheduleClassCard = ScheduleCard;
