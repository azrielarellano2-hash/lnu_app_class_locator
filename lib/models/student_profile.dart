class StudentProfile {
  const StudentProfile({
    required this.id,
    this.idNumber,
    this.name,
    this.college,
    this.course,
    this.year,
    this.section,
    this.profilePhotoPath,
    this.bio,
    this.semester,
    this.academicYear,
    this.formNumber,
  });

  final String id;
  final String? idNumber;
  final String? name;
  final String? college;
  final String? course;
  final String? year;
  final String? section;
  final String? profilePhotoPath;
  final String? bio;
  final String? semester;
  final String? academicYear;
  final String? formNumber;

  factory StudentProfile.fromRow(Map<String, Object?> row) {
    return StudentProfile(
      id: row['id'] as String,
      idNumber: row['id_number'] as String?,
      name: row['name'] as String?,
      college: row['college'] as String?,
      course: row['course'] as String?,
      year: row['year'] as String?,
      section: row['section'] as String?,
      profilePhotoPath: row['profile_photo_path'] as String?,
      bio: row['bio'] as String?,
      semester: row['semester'] as String?,
      academicYear: row['academic_year'] as String?,
      formNumber: row['form_number'] as String?,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'id_number': idNumber,
        'name': name,
        'college': college,
        'course': course,
        'year': year,
        'section': section,
        'profile_photo_path': profilePhotoPath,
        'bio': bio,
        'semester': semester,
        'academic_year': academicYear,
        'form_number': formNumber,
      };

  StudentProfile copyWith({
    String? idNumber,
    String? name,
    String? college,
    String? course,
    String? year,
    String? section,
    String? profilePhotoPath,
    String? bio,
    String? semester,
    String? academicYear,
    String? formNumber,
  }) {
    return StudentProfile(
      id: id,
      idNumber: idNumber ?? this.idNumber,
      name: name ?? this.name,
      college: college ?? this.college,
      course: course ?? this.course,
      year: year ?? this.year,
      section: section ?? this.section,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      bio: bio ?? this.bio,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      formNumber: formNumber ?? this.formNumber,
    );
  }
}
