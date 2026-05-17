import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../utils/ocr_line_grouper.dart';

/// Runs on-device text recognition (ML Kit). Use on Android / iOS only.
class EslipOcrService {
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Returns plain text from a JPEG/PNG photo path, grouped into table rows.
  Future<String> recognizeFromFilePath(String path) async {
    final input = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(input);
      return groupRecognizedTextIntoRows(result);
    } finally {
      await recognizer.close();
    }
  }
}
