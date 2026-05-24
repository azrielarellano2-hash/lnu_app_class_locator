import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Picks a profile photo and stores it in app documents so the path persists.
class ProfilePhotoService {
  const ProfilePhotoService();

  static Future<ImageSource?> chooseImageSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> pickAndPersist({
    required ImageSource source,
    required String fileName,
  }) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return null;
    return persist(picked.path, fileName: fileName);
  }

  Future<String> persist(String sourcePath, {required String fileName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'profile_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final destPath = p.join(photosDir.path, fileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }
}
