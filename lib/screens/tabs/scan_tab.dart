import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lnu_app_class_locator/navigation/home_tabs.dart';
import 'package:lnu_app_class_locator/services/eslip_image_capture_service.dart';
import 'package:lnu_app_class_locator/services/eslip_ocr_service.dart';
import 'package:lnu_app_class_locator/state/app_repository.dart';
import 'package:lnu_app_class_locator/screens/eslip_detection_screen.dart';
import 'package:lnu_app_class_locator/widgets/student_green_header.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key, required this.onOpenTab});

  /// Switch main tabs when bottom navigation is hidden on this screen.
  final HomeTabSelectedCallback onOpenTab;

  @override
  State<ScanTab> createState() => _ScanTabState();
}

enum _EslipCaptureChoice { gallery, camera }

enum _CameraCaptureChoice { documentCameraManual, normalCam }

class _ScanTabState extends State<ScanTab> {
  final _capture = const EslipImageCaptureService();

  Future<void> _scanEslip(AppRepository repo) async {
    if (!EslipOcrService.isSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-slip scanning runs on Android or iOS devices.')),
      );
      return;
    }

    final choice = await showModalBottomSheet<_EslipCaptureChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSourceSheet(theme: Theme.of(ctx)),
    );
    if (choice == null || !mounted) return;

    final String? imagePath;
    switch (choice) {
      case _EslipCaptureChoice.gallery:
        imagePath = await _capture.pickFromGallery();
      case _EslipCaptureChoice.camera:
        final cameraChoice = await showModalBottomSheet<_CameraCaptureChoice>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _CameraChoiceSheet(
            theme: Theme.of(ctx),
            documentCameraAvailable:
                EslipImageCaptureService.documentScannerSupported,
          ),
        );
        if (cameraChoice == null || !mounted) return;
        imagePath = switch (cameraChoice) {
          _CameraCaptureChoice.documentCameraManual =>
            await _capture.captureWithDocumentCameraManual(),
          _CameraCaptureChoice.normalCam =>
            await _capture.captureWithNormalCamera(),
        };
    }
    if (imagePath == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(c).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12))],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                SizedBox(width: 18),
                Text('Reading e-slip…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final raw = await EslipOcrService().recognizeFromFilePath(imagePath);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (raw.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No text detected. Use a sharper photo with the full enrolment table in frame.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final result = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) => EslipDetectionScreen(ocrRaw: raw),
        ),
      );
      if (!mounted || result is! Map) return;
      final imported = result['imported'] as int? ?? 0;
      if (imported > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$imported classes saved to your schedule')),
        );
        widget.onOpenTab(HomeTabs.schedule);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read the image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Column(
        children: [
          StudentGreenHeader(
            title: 'Extractor',
            subtitle: 'Scan your LNU enrolment form — schedule imports automatically',
            leading: const Icon(
              Icons.document_scanner_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Color(0x28000000), blurRadius: 28, offset: Offset(0, 14)),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _scanEslip(repo),
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: const Text('Scan e-slip (OCR)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'How it works',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• We verify your image is an enrolment / assessment form.\n'
                            '• Your schedule is extracted automatically — no manual row editing.\n'
                            '• MTh, TF, and W day codes are preserved (Wednesday included).\n'
                            '• Lecture and lab rows stay separate (e.g. IT-121 vs IT-121L).\n'
                            '• Camera: Document Camera "Manual" (crop) or Normal Cam.\n'
                            '• Tip: photograph the full table flat, in good light.',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              height: 1.45,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return _CaptureBottomSheet(
      scheme: scheme,
      title: 'Scan e-slip',
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.photo_library_outlined, color: scheme.onPrimaryContainer),
          ),
          title: const Text('Gallery'),
          subtitle: const Text('Existing photo of your e-slip'),
          onTap: () => Navigator.pop(context, _EslipCaptureChoice.gallery),
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            child: Icon(Icons.photo_camera_outlined, color: scheme.onSecondaryContainer),
          ),
          title: const Text('Camera'),
          subtitle: const Text('Document Camera "Manual" or Normal Cam'),
          onTap: () => Navigator.pop(context, _EslipCaptureChoice.camera),
        ),
      ],
    );
  }
}

class _CameraChoiceSheet extends StatelessWidget {
  const _CameraChoiceSheet({
    required this.theme,
    required this.documentCameraAvailable,
  });

  final ThemeData theme;
  final bool documentCameraAvailable;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return _CaptureBottomSheet(
      scheme: scheme,
      title: 'Camera',
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.tertiaryContainer,
            child: Icon(Icons.document_scanner_outlined, color: scheme.onTertiaryContainer),
          ),
          title: const Text('Document Camera "Manual"'),
          subtitle: Text(
            documentCameraAvailable
                ? 'Detect edges, adjust corners, then crop'
                : 'Not available on this device',
          ),
          enabled: documentCameraAvailable,
          onTap: documentCameraAvailable
              ? () => Navigator.pop(context, _CameraCaptureChoice.documentCameraManual)
              : null,
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            child: Icon(Icons.photo_camera_outlined, color: scheme.onSecondaryContainer),
          ),
          title: const Text('Normal Cam'),
          subtitle: const Text('Standard camera — no auto crop'),
          onTap: () => Navigator.pop(context, _CameraCaptureChoice.normalCam),
        ),
      ],
    );
  }
}

class _CaptureBottomSheet extends StatelessWidget {
  const _CaptureBottomSheet({
    required this.scheme,
    required this.title,
    required this.children,
  });

  final ColorScheme scheme;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: scheme.surface,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                ...children,
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
