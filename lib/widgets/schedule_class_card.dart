import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/parsed_schedule_display.dart';
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

  static const Color _timeGreen = Color(0xFF1B5E20);
  static const Color _cardFill = Color(0xFFF1F8F2);
  static const Color _cardFillSelected = Color(0xFFE8F5E9);
  static const Color _descriptionBlack = Color(0xFF1A1A1A);
  static const Color _roomBlack = Color(0xFF2C2C2C);
  static const Color _mutedGray = Color(0xFF616161);

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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: _timeGreen,
              letterSpacing: -0.2,
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
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: _descriptionBlack,
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.25,
              color: _roomBlack,
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
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.35,
              color: _mutedGray,
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
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.35,
              color: _mutedGray,
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
      elevation: isSelected ? 3 : 2,
      shadowColor: Colors.black26,
      color: isSelected ? _cardFillSelected : _cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF43A047).withValues(alpha: 0.35)
              : const Color(0xFFC8E6C9).withValues(alpha: 0.5),
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
