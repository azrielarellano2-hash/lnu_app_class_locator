import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Horizontal Mon–Sat date picker for the weekly schedule screen.
class WeekDayStrip extends StatelessWidget {
  const WeekDayStrip({
    super.key,
    required this.week,
    required this.selectedIndex,
    required this.onSelected,
  });

  final WeeklySchedule week;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i >= week.days.length) return const SizedBox.shrink();
          final day = week.days[i];
          final date = DateTime.parse(day.dateIso);
          final selected = i == selectedIndex;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(i),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String formatSelectedDateLabel(WeeklyDay day) {
    final d = DateTime.parse(day.dateIso);
    return DateFormat('EEEE, MMMM d, yyyy').format(d);
  }
}
