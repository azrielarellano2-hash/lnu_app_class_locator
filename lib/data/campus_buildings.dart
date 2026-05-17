import 'campus_assets.dart';

/// Rooms → Buildings: photo, title, and tap-to-read walking guide.
class CampusBuildingGuide {
  const CampusBuildingGuide({
    required this.title,
    required this.sheetTitle,
    required this.assetPath,
    required this.whatYouAreSeeing,
    required this.howToGetThere,
  });

  final String title;
  final String sheetTitle;
  final String assetPath;
  final String whatYouAreSeeing;
  final String howToGetThere;
}

/// Order matches the Buildings tab. Asset paths corrected (CON vs IT).
const List<CampusBuildingGuide> kCampusBuildingGuides = [
  CampusBuildingGuide(
    title: 'Academic Building',
    sheetTitle: 'Academic Building',
    assetPath: kAcademicBuildingPhoto,
    whatYouAreSeeing:
        "That huge, beautiful curved white building with rows of arched windows and the big LNU seal in the middle? That's the Academic Building — the most famous building in the whole campus!",
    howToGetThere:
        "Okay so when you walk through the Youngfield Gate (the main entrance), just walk straight forward. Don't turn left, don't turn right — just go straight ahead. After just a few steps inside, you'll already start to see it in front of you. The building is SO big and SO wide that you really can't miss it. Just keep walking toward that big LNU seal and you're there!",
  ),
  CampusBuildingGuide(
    title: 'ORC Building',
    sheetTitle: 'ORC BUILDING',
    assetPath: kOrcBuildingPhoto,
    whatYouAreSeeing:
        "That open, pavilion-style building with a wide sloping roof and a big grassy lawn in front full of students sitting and relaxing? That's the ORC Building — the most popular chill spot in all of LNU!",
    howToGetThere:
        "Okay, this one you need to go deeper into the campus. From the ACAD Building, keep walking further inside campus — away from the main gate. As you walk deeper, look for the Fish Pond area (the shaded garden pathway with big trees and trimmed shrubs). Once you find the yellow directional signboard in the Fish Pond area, follow the arrow that says \"ORC BUILDING →\" — turn in that direction and keep walking. Soon you'll see the wide open pavilion and the big green lawn in front of it. You'll probably hear the students laughing and chatting before you even see the building!",
  ),
  CampusBuildingGuide(
    title: 'Conversion Building',
    sheetTitle: 'CONVERSION BUILDING',
    assetPath: kConversionBuildingPhoto,
    whatYouAreSeeing:
        'That wide white building set behind an iron fence with lots of AC units on the windows and big trees partially blocking the view from the road?',
    howToGetThere:
        "From the Youngfield Gate, instead of going straight toward the ACAD Building, look along the road that runs beside the campus perimeter. The CON Building faces outward toward the street, so you can actually see it from the road side. Walk along the campus boundary road and look for the wide white building behind iron fencing. The big trees in front of it make it look a little hidden, but just look past the trees and you'll see it clearly.",
  ),
  CampusBuildingGuide(
    title: 'IT Building',
    sheetTitle: 'IT BUILDING (Information Technology Building)',
    assetPath: kItBuildingPhoto,
    whatYouAreSeeing:
        "That two-story building almost completely surrounded and covered by big trees, with a metal outdoor staircase and a small covered extension walkway? That's the IT Building — tucked away in the tree-covered interior of campus!",
    howToGetThere:
        "This one is the trickiest to find, so pay close attention! 😄 From the COMLAB Building, don't go back toward the gate — instead, go a little further deeper into the campus, past the COMLAB. The IT Building is right nearby but hidden behind thick trees. Walk slowly and look carefully between the trees and branches. You're looking for a modest two-story building that looks almost like it's being hugged by the trees around it. Look for the metal outdoor staircase on the side and a small CLAYGO (Clean As You Go) sign near the entrance — those are your clues that you've found it!",
  ),
  CampusBuildingGuide(
    title: 'Science Building',
    sheetTitle: 'SCIENCE BUILDING',
    assetPath: kScienceBuildingPhoto,
    whatYouAreSeeing:
        "That building with the reddish-brown brick upper floors, multiple levels, and iron fencing along the road in front? That's the Science Building — where science labs and classes happen!",
    howToGetThere:
        "From the Paterno Gate, walk along the road that follows the campus perimeter — the same direction where the CON Building is. The Science Building is along that same stretch of road, close to or near the CON Building. Look for the building that stands out because of its reddish-brown or terracotta colored bricks on the upper floors — it looks earthier and darker compared to the white buildings around it. When you see that reddish-brown color from the road, you've found it!",
  ),
];
