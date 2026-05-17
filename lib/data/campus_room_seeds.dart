/// Extra [campus_rooms] rows (LNU-style codes). Inserted with CONFLICT IGNORE.
List<Map<String, Object?>> extendedCampusRoomSeedRows() {
  final rows = <Map<String, Object?>>[
    {
      'code': 'ICT-301',
      'building': 'IT Building',
      'floor': '3',
      'description': 'Computer laboratory wing',
    },
    {
      'code': 'LAB-2',
      'building': 'Science Building',
      'floor': '2',
      'description': 'Laboratory room',
    },
    {
      'code': 'RM-105',
      'building': 'Administration Building',
      'floor': '1',
      'description': 'Lecture hall',
    },
    {
      'code': 'LIB-READ',
      'building': 'Learning Resource Center',
      'floor': '2',
      'description': 'Reading area / seminar room',
    },
  ];

  void add(String code, String building, String floor, String description) {
    rows.add({
      'code': code,
      'building': building,
      'floor': floor,
      'description': description,
    });
  }

  for (var lab = 1; lab <= 6; lab++) {
    for (final wing in ['A', 'B', 'C', 'D']) {
      add(
        'COMLAB$lab$wing',
        'IT Building',
        '$lab',
        'Computer laboratory',
      );
    }
  }
  for (var n = 1; n <= 9; n++) {
    add('COMLAB$n', 'IT Building', '$n', 'Computer laboratory');
  }

  for (final code in ['LRC-101', 'LRC-102', 'LRC-103', 'LRC-201', 'LRC-202', 'LRC-301', 'LRC-302']) {
    add(code, 'Learning Resource Center', code.split('-').last.substring(0, 1), 'LRC room');
  }

  for (final code in ['SCI-101', 'SCI-102', 'SCI-201', 'SCI-202', 'SCI-301']) {
    add(code, 'Science Building', code.substring(4, 5), 'Science laboratory / lecture');
  }

  add('AUD-1', 'Montejo Building', '1', 'Auditorium / large hall');
  add('GYM-MAIN', 'Gym', '1', 'Main gymnasium');
  add('ACAD-101', 'Academic Building', '1', 'Classroom');
  add('ACAD-201', 'Academic Building', '2', 'Classroom');
  add('COL-101', 'College Building', '1', 'Classroom');
  add('COL-201', 'College Building', '2', 'Classroom');
  add('GS-101', 'Graduate School', '1', 'Graduate classroom');
  add('ENT-101', 'Entrepreneurship Building', '1', 'Classroom / workshop');
  add('HUM-101', 'Humanities Building', '1', 'Lecture room');
  add('CTELL-101', 'CTELL Building', '1', 'Technology / lecture room');
  add('BRILLO-101', 'Brillo Hall', '1', 'Hall / venue');
  add('CME-101', 'CME Building', '1', 'Classroom');
  add('CONV-101', 'Conversion Building', '1', 'Room');

  return rows;
}
