/// LNU main campus — building numbers from the official master plan map (static reference).
class CampusMapBuilding {
  const CampusMapBuilding({
    required this.number,
    required this.name,
    required this.compound,
  });

  final int number;
  final String name;
  final String compound;
}

/// Legend keyed to red circles on the static campus map.
const List<CampusMapBuilding> lnuMainCampusMapLegend = [
  CampusMapBuilding(number: 1, name: 'ORC Building', compound: 'Admin'),
  CampusMapBuilding(number: 2, name: 'ORC Stage', compound: 'Admin'),
  CampusMapBuilding(number: 3, name: 'Guard House', compound: 'Admin'),
  CampusMapBuilding(number: 4, name: 'Guard House', compound: 'Admin'),
  CampusMapBuilding(number: 5, name: 'CEMP Canteen', compound: 'Admin'),
  CampusMapBuilding(number: 6, name: 'Administration Building', compound: 'Admin'),
  CampusMapBuilding(number: 7, name: 'Brillo Hall', compound: 'Admin'),
  CampusMapBuilding(number: 8, name: 'CTELL Building', compound: 'Admin'),
  CampusMapBuilding(number: 9, name: 'Humanities Building', compound: 'Admin'),
  CampusMapBuilding(number: 10, name: 'IT Building', compound: 'Admin'),
  CampusMapBuilding(number: 11, name: 'Student Center', compound: 'Admin'),
  CampusMapBuilding(number: 12, name: 'HRDC Building', compound: 'Admin'),
  CampusMapBuilding(number: 13, name: 'Covered Basketball Court', compound: 'Admin'),
  CampusMapBuilding(number: 14, name: 'IGP Food Court', compound: 'Admin'),
  CampusMapBuilding(number: 15, name: 'Montejo Building', compound: 'Admin'),
  CampusMapBuilding(number: 16, name: 'Guard House', compound: 'College'),
  CampusMapBuilding(number: 17, name: 'College Building', compound: 'College'),
  CampusMapBuilding(number: 18, name: 'IGP Food Park', compound: 'College'),
  CampusMapBuilding(number: 19, name: 'Science Building', compound: 'College'),
  CampusMapBuilding(number: 20, name: 'Learning Resource Center', compound: 'College'),
  CampusMapBuilding(number: 21, name: 'LNU House', compound: 'College'),
  CampusMapBuilding(number: 22, name: 'Entrepreneurship Building', compound: 'College'),
  CampusMapBuilding(number: 23, name: 'Graduate School', compound: 'College'),
  CampusMapBuilding(number: 24, name: 'Guard House', compound: 'Youngfield'),
  CampusMapBuilding(number: 25, name: 'Conversion Building', compound: 'Youngfield'),
  CampusMapBuilding(number: 26, name: 'De Venecia Building', compound: 'Youngfield'),
  CampusMapBuilding(number: 27, name: 'Hotel Cresencia', compound: 'Youngfield'),
  CampusMapBuilding(number: 28, name: 'CME Building', compound: 'Youngfield'),
  CampusMapBuilding(number: 29, name: 'IGP Food Park', compound: 'Youngfield'),
  CampusMapBuilding(number: 30, name: 'Gym', compound: 'Youngfield'),
  CampusMapBuilding(number: 31, name: 'Male and Female Student Dormitory', compound: 'Youngfield'),
  CampusMapBuilding(number: 32, name: 'Academic Building', compound: 'Youngfield'),
  CampusMapBuilding(number: 33, name: 'Guard House', compound: 'Youngfield'),
  CampusMapBuilding(number: 34, name: 'Faculty Dorm', compound: 'Youngfield'),
  CampusMapBuilding(number: 35, name: 'Dormitory', compound: 'Youngfield'),
  CampusMapBuilding(number: 36, name: 'Guest House', compound: 'Youngfield'),
];
