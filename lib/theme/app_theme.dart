import 'package:flutter/material.dart';

class AppColors {
  static const primary       = Color(0xFF16A34A);
  static const primaryDark   = Color(0xFF14532D);
  static const primaryLight  = Color(0xFFDCFCE7);
  static const background    = Color(0xFFF8F9FA);
  static const surface       = Colors.white;
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint      = Color(0xFF9CA3AF);
  static const border        = Color(0xFFE5E7EB);
  static const onHeaderMuted = Color(0xFF86EFAC);

  static const _accents = [
    Color(0xFF16A34A), Color(0xFF0D9488), Color(0xFF7C3AED),
    Color(0xFFD97706), Color(0xFF0EA5E9), Color(0xFFDB2777),
  ];
  static Color subjectAccent(String code) {
    final key = code.split('-').first.toUpperCase();
    return _accents[key.hashCode.abs() % _accents.length];
  }
}

const kCardShadow = [
  BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2)),
];

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary, brightness: Brightness.light),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryLight,
      elevation: 0,
      height: 64,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textHint,
      )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
        size: 22,
        color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textHint,
      )),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFF3F4F6), thickness: 1, space: 1),
  );
}
