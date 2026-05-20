import 'package:flutter/services.dart';

import '../constants/app_assets.dart';

/// PNG bytes of the official LNU seal for PDF / print headers.
Future<Uint8List> loadLnuSealBytes() async {
  final data = await rootBundle.load(kLnuSealAsset);
  return data.buffer.asUint8List();
}

/// @deprecated Use [loadLnuSealBytes]; kept for PDF builder compatibility.
Future<Uint8List> rasterizeAppLogo({double size = 96}) => loadLnuSealBytes();
