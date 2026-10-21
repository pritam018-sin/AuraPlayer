import 'package:flutter/material.dart';

class AppTheme {
  // Aura Cinema Pro Design System (Obsidian Velvet, Electric Cyan & Cinema Gold)
  static const Color background = Color(0xFF07080B);
  static const Color surface = Color(0xFF0F1117);
  static const Color surfaceSecondary = Color(0xFF171A23);
  static const Color surfaceTertiary = Color(0xFF222634);

  // Modern Cinema Pro Accents
  static const Color accent = Color(0xFF00D2FF); // Electric Cinema Cyan
  static const Color accentDark = Color(0xFF0284C7);
  static const Color accentAmber = Color(0xFFF59E0B); // Cinema Amber
  static const Color accentGold = Color(0xFFFBBF24); // Cinema Gold
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentEmerald = Color(0xFF10B981); // Live Broadcast Emerald
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentPurple = Color(0xFFA855F7);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  static const Color accentHover = Color(0xFF38BDF8);
  static const Color trafficRed = Color(0xFFFF5F56);
  static const Color trafficYellow = Color(0xFFFFBD2E);
  static const Color trafficGreen = Color(0xFF27C93F);

  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorderHover = Color(0x33FFFFFF); // 20% white
  static const Color glassFill = Color(0xCC0F1117); // 80% opacity
  static const Color controlPillFill = Color(0xE0171A23); // 88% opacity

  // Gradients
  static const LinearGradient auraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D2FF), Color(0xFF0284C7)],
  );

  static const LinearGradient cinemaGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
  );

  static const LinearGradient auraCyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), Color(0xFF2563EB)],
  );

  static const LinearGradient liveBadgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
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
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
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
