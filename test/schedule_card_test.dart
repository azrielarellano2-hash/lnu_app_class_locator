import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lnu_app_class_locator/models/parsed_schedule_display.dart';
import 'package:lnu_app_class_locator/widgets/schedule_class_card.dart';

void main() {
  const sample = ParsedScheduleDisplay(
    startTime: '8:00 AM',
    endTime: '9:00 AM',
    subjectCode: 'IT-122',
    subjectTitle: 'System Analysis and Design',
    subjectName: 'IT-122 System Analysis and Design',
    roomCode: 'COMLAB2A',
    instructor: 'M. Gotardo',
    dayPattern: 'Monday and Thursday',
    dayToken: 'MTh',
    startTimeRaw: '08:00',
    endTimeRaw: '09:00',
  );

  testWidgets('renders five structured lines in order', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScheduleCard(parsed: sample),
        ),
      ),
    );

    expect(find.text('8:00 AM – 9:00 AM'), findsOneWidget);
    expect(find.text('IT-122 System Analysis and Design'), findsOneWidget);
    expect(find.text('COMLAB2A'), findsOneWidget);
    expect(find.text('Instructor: M. Gotardo'), findsOneWidget);
    expect(find.text('Monday and Thursday'), findsOneWidget);
    expect(find.textContaining('8-9 am'), findsNothing);
    expect(find.textContaining('MTh COMLAB'), findsNothing);
  });
}
