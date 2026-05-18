import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/formatters.dart';
import '../utils/subject_color.dart';
import 'schedule_detail_sheet.dart';

/// Interactive Mon–Sat × time grid (7:00–21:00, 30-minute rows).
class WeeklyScheduleGrid extends StatelessWidget {
  const WeeklyScheduleGrid({
    super.key,
    required this.week,
    this.customLabels = const {},
  });

  final WeeklySchedule week;
  final Map<String, String> customLabels;

  static const _startHour = 7;
  static const _endHour = 21;
  static const _slotMinutes = 30;
  static const _rowHeight = 28.0;
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _labelWidth = 44.0;
  static const _dayWidth = 88.0;

  int get _rowCount => ((_endHour - _startHour) * 60 / _slotMinutes).round();

  double _minutesFromMidnight(String hm) {
    final p = hm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = <_Block>[];
    for (var d = 0; d < 6 && d < week.days.length; d++) {
      final day = week.days[d];
      if (day.weekdayIndex > 5) continue;
      for (final slot in day.slots) {
        if (slot.dayOfWeek > 5) continue;
        final startMin = _minutesFromMidnight(slot.startTime);
        final endMin = _minutesFromMidnight(slot.endTime);
        final gridStart = _startHour * 60;
        final top = ((startMin - gridStart) / _slotMinutes) * _rowHeight;
        final height = ((endMin - startMin) / _slotMinutes) * _rowHeight;
        if (height <= 0) continue;
        blocks.add(_Block(
          dayIndex: slot.dayOfWeek.clamp(0, 5),
          top: top.clamp(0, _rowCount * _rowHeight),
          height: height.clamp(_rowHeight * 0.5, _rowCount * _rowHeight),
          slot: slot,
          colorTag: customLabels[slot.subjectName],
        ));
      }
    }

    final overlapGroups = _assignOverlapColumns(blocks);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _labelWidth + _dayWidth * 6,
        height: _rowCount * _rowHeight + 32,
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 28,
                  child: Row(
                    children: [
                      const SizedBox(width: _labelWidth),
                      ...List.generate(
                        6,
                        (i) => SizedBox(
                          width: _dayWidth,
                          child: Center(
                            child: Text(
                              _dayLabels[i],
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...List.generate(_rowCount, (row) {
                  final hour = _startHour + (row * _slotMinutes ~/ 60);
                  final minute = (row * _slotMinutes) % 60;
                  final label = minute == 0
                      ? formatHm('${hour.toString().padLeft(2, '0')}:00')
                      : '';
                  return SizedBox(
                    height: _rowHeight,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _labelWidth,
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        ...List.generate(
                          6,
                          (_) => Container(
                            width: _dayWidth,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: row.isOdd ? 0.5 : 1,
                                ),
                                right: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            ...overlapGroups.map((b) {
              final colW = _dayWidth / b.columnCount;
              final left = _labelWidth + b.dayIndex * _dayWidth + b.column * colW;
              final color = b.colorTag != null
                  ? Color(int.parse(b.colorTag!.replaceFirst('#', '0xFF')))
                  : subjectBlockColor(b.slot.subjectName);
              return Positioned(
                top: 28 + b.top,
                left: left + 2,
                width: colW - 4,
                height: b.height,
                child: _SubjectBlock(
                  slot: b.slot,
                  color: color,
                  heroTag: 'subject_${b.slot.id}',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<_Block> _assignOverlapColumns(List<_Block> blocks) {
    final sorted = List<_Block>.from(blocks)
      ..sort((a, b) {
        final d = a.dayIndex.compareTo(b.dayIndex);
        if (d != 0) return d;
        return a.top.compareTo(b.top);
      });

    for (var i = 0; i < sorted.length; i++) {
      final a = sorted[i];
      var cols = 1;
      var col = 0;
      final overlapping = <_Block>[];
      for (var j = 0; j < sorted.length; j++) {
        if (i == j) continue;
        final b = sorted[j];
        if (b.dayIndex != a.dayIndex) continue;
        if (a.top < b.top + b.height && b.top < a.top + a.height) {
          overlapping.add(b);
        }
      }
      if (overlapping.isNotEmpty) {
        cols = overlapping.map((o) => o.columnCount).fold(1, (m, c) => c > m ? c : m) + 1;
        final used = overlapping.map((o) => o.column).toSet();
        while (used.contains(col)) {
          col++;
        }
      }
      sorted[i] = _Block(
        dayIndex: a.dayIndex,
        top: a.top,
        height: a.height,
        slot: a.slot,
        colorTag: a.colorTag,
        column: col,
        columnCount: cols,
      );
    }
    return sorted;
  }
}

class _Block {
  const _Block({
    required this.dayIndex,
    required this.top,
    required this.height,
    required this.slot,
    this.colorTag,
    this.column = 0,
    this.columnCount = 1,
  });

  final int dayIndex;
  final double top;
  final double height;
  final ScheduleSlot slot;
  final String? colorTag;
  final int column;
  final int columnCount;
}

class _SubjectBlock extends StatelessWidget {
  const _SubjectBlock({
    required this.slot,
    required this.color,
    required this.heroTag,
  });

  final ScheduleSlot slot;
  final Color color;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => showScheduleDetailSheet(
          context,
          slot: slot,
          heroTag: heroTag,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.subjectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                slot.roomCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9),
              ),
              Text(
                formatTimeRange(slot.startTime, slot.endTime),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
