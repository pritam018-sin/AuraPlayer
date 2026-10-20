import 'package:flutter/material.dart';

class AppTheme {
  // Aura Design System (Obsidian & Neon Glass)
  static const Color background = Color(0xFF070709);
  static const Color surface = Color(0xFF121216);
  static const Color surfaceSecondary = Color(0xFF1C1C23);
  static const Color surfaceTertiary = Color(0xFF262630);

  // Aura Signature Crimson / Rose Accent
  static const Color accent = Color(0xFFFA2D48);
  static const Color accentDark = Color(0xFFE11D48);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentPurple = Color(0xFFA855F7);

  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);

  static const Color accentHover = Color(0xFFFF4D67);
  static const Color trafficRed = Color(0xFFFF5F56);
  static const Color trafficYellow = Color(0xFFFFBD2E);
  static const Color trafficGreen = Color(0xFF27C93F);

  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorderHover = Color(0x33FFFFFF); // 20% white
  static const Color glassFill = Color(0xB8121216); // 72% opacity #121216
  static const Color controlPillFill = Color(0xD0121216); // 82% opacity

  // Gradients
  static const LinearGradient auraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFA2D48), Color(0xFFE11D48)],
  );

  static const LinearGradient auraCyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  );

  // Type Scale
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: -0.1,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    letterSpacing: -0.25,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        onSurface: textPrimary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: caption.copyWith(color: textPrimary, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}
