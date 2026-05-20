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
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: lightBackground ? 0.18 : 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: lightBackground
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.5),
              width: 2,
            ),
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
          Text(
            'Offline-Friendly',
            style: TextStyle(
              color: lightBackground ? fg : Colors.white.withValues(alpha: 0.92),
              fontSize: size * 0.09,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
}
