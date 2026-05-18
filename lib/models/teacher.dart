import 'dart:convert';

class Teacher {
  const Teacher({
    required this.id,
    required this.name,
    this.position,
    this.department,
    this.college,
    this.email,
    this.contactNumber,
    this.profilePhotoPath,
    this.bio,
    this.yearsOfService,
    this.officeHours,
    this.officeRoom,
    this.subjectsTaught = const [],
    this.socialLinks = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? position;
  final String? department;
  final String? college;
  final String? email;
  final String? contactNumber;
  final String? profilePhotoPath;
  final String? bio;
  final int? yearsOfService;
  final String? officeHours;
  final String? officeRoom;
  final List<String> subjectsTaught;
  final Map<String, String> socialLinks;
  final int createdAt;
  final int updatedAt;

  factory Teacher.fromRow(Map<String, Object?> row) {
    List<String> subjects = [];
    final st = row['subjects_taught'] as String?;
    if (st != null && st.isNotEmpty) {
      subjects = (jsonDecode(st) as List<dynamic>).cast<String>();
    }
    Map<String, String> links = {};
    final sl = row['social_links'] as String?;
    if (sl != null && sl.isNotEmpty) {
      links = Map<String, String>.from(jsonDecode(sl) as Map);
    }
    return Teacher(
      id: row['id'] as String,
      name: row['name'] as String,
      position: row['position'] as String?,
      department: row['department'] as String?,
      college: row['college'] as String?,
      email: row['email'] as String?,
      contactNumber: row['contact_number'] as String?,
      profilePhotoPath: row['profile_photo_path'] as String?,
      bio: row['bio'] as String?,
      yearsOfService: row['years_of_service'] as int?,
      officeHours: row['office_hours'] as String?,
      officeRoom: row['office_room'] as String?,
      subjectsTaught: subjects,
      socialLinks: links,
      createdAt: row['created_at'] as int,
      updatedAt: row['updated_at'] as int,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'position': position,
        'department': department,
        'college': college,
        'email': email,
        'contact_number': contactNumber,
        'profile_photo_path': profilePhotoPath,
        'bio': bio,
        'years_of_service': yearsOfService,
        'office_hours': officeHours,
        'office_room': officeRoom,
        'subjects_taught': jsonEncode(subjectsTaught),
        'social_links': jsonEncode(socialLinks),
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Teacher copyWith({
    String? name,
    String? position,
    String? department,
    String? college,
    String? email,
    String? contactNumber,
    String? profilePhotoPath,
    String? bio,
    int? yearsOfService,
    String? officeHours,
    String? officeRoom,
    List<String>? subjectsTaught,
    Map<String, String>? socialLinks,
    int? updatedAt,
  }) {
    return Teacher(
      id: id,
      name: name ?? this.name,
      position: position ?? this.position,
      department: department ?? this.department,
      college: college ?? this.college,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      bio: bio ?? this.bio,
      yearsOfService: yearsOfService ?? this.yearsOfService,
      officeHours: officeHours ?? this.officeHours,
      officeRoom: officeRoom ?? this.officeRoom,
      subjectsTaught: subjectsTaught ?? this.subjectsTaught,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
