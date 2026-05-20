import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Captures e-slip images: document scanner for camera, gallery picker otherwise.
class EslipImageCaptureService {
  const EslipImageCaptureService();

  static bool get documentScannerSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Document camera with manual edge adjust + crop (ML Kit / iOS document scanner).
  Future<String?> captureWithDocumentCameraManual() async {
    if (!documentScannerSupported) return null;

    try {
      final paths = await CunningDocumentScanner.getPictures(
        noOfPages: 1,
        isGalleryImportAllowed: false,
        iosScannerOptions: const IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: 0.88,
        ),
      );
      if (paths == null || paths.isEmpty) return null;
      return paths.first;
    } catch (e) {
      debugPrint('Document camera (manual) failed: $e');
      return null;
    }
  }

  /// Standard phone camera — no document edge detection.
  Future<String?> captureWithNormalCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
    );
    return picked?.path;
  }

  /// Existing photo from the device gallery.
  Future<String?> pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    return picked?.path;
  }
}
