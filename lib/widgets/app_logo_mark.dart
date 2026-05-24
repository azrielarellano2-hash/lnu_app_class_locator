import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_theme.dart';

/// Official LNU seal — welcome screen and in-app branding.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    this.size = 152,
    this.showTagline = true,
    this.lightBackground = true,
  });

  final double size;
  final bool showTagline;
  /// When false (e.g. green welcome gradient), seal sits on a white disc.
  final bool lightBackground;

  @override
  Widget build(BuildContext context) {
    final fg = lightBackground ? AppColors.primary : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              kLnuSealAsset,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, error, _) => SizedBox(
                width: size,
                height: size,
                child: Icon(Icons.school, size: size * 0.5, color: fg),
              ),
            ),
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: size * 0.08),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Works offline',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
