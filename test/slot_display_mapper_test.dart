import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/models/models.dart';
import 'package:lnu_app_class_locator/utils/slot_display_mapper.dart';

void main() {
  test('distinctClassBlocksFromSlots dedupes MTh double rows', () {
    final slots = [
      ScheduleSlot(
        id: 1,
        subjectName: 'IT-122',
        roomCode: 'COMLAB2A',
        dayOfWeek: 0,
        startTime: '08:00:00',
        endTime: '09:00:00',
        dayPattern: 'MTh',
        subjectTitle: 'System Analysis and Design',
        instructorName: 'M. Gotardo',
      ),
      ScheduleSlot(
        id: 2,
        subjectName: 'IT-122',
        roomCode: 'COMLAB2A',
        dayOfWeek: 3,
        startTime: '08:00:00',
        endTime: '09:00:00',
        dayPattern: 'MTh',
        subjectTitle: 'System Analysis and Design',
        instructorName: 'M. Gotardo',
      ),
      ScheduleSlot(
        id: 3,
        subjectName: 'GE-117',
        roomCode: 'TBA11A',
        dayOfWeek: 0,
        startTime: '13:00:00',
        endTime: '14:30:00',
        dayPattern: 'MTh',
        subjectTitle: 'The Entrepreneurial Mind (Elective)',
        instructorName: 'A. Parena',
      ),
    ];

    final blocks = distinctClassBlocksFromSlots(slots);
    expect(blocks.length, 2);
    expect(blocks[0].subjectCode, 'IT-122');
    expect(blocks[1].subjectCode, 'GE-117');
  });
}
