import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class AboutModal extends StatelessWidget {
  const AboutModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: const AboutModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final cardBg = isDark
        ? const Color(0xFF0C101A).withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.65);
    final innerBg = isDark
        ? AppTheme.surfaceSecondary.withValues(alpha: 0.50)
        : Colors.white.withValues(alpha: 0.70);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FrostedGlass(
          borderRadius: 22,
          padding: const EdgeInsets.all(28),
          fillColor: cardBg,
          borderColor: borderCol,
          blur: 35,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.4),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title & Version
                Text(
                  'AuraPlayer',
                  style: AppTheme.display.copyWith(
                    fontSize: 24,
                    letterSpacing: 0.5,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Version 1.0.0 (Windows Release)',
                    style: AppTheme.caption.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),

                // Brand details
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: innerBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Organization', 'AuraStudio Corporation', textSecondary, textPrimary),
                      Divider(color: borderCol, height: 16),
                      _infoRow('Creator & Lead', 'Pritam', textSecondary, textPrimary),
                      Divider(color: borderCol, height: 16),
                      _infoRow('Engine', 'libmpv-2 + Flutter D3D11 Native', textSecondary, textPrimary),
                      Divider(color: borderCol, height: 16),
                      _infoRow('License', 'AuraStudio Software License', textSecondary, textPrimary),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  '© 2026 AuraStudio Corporation by Pritam.\nAll rights reserved. Powered by AuraStudio.',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption.copyWith(color: textSecondary, fontSize: 11, height: 1.4),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: const Color(0xFF04131F),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.caption.copyWith(color: labelColor)),
        Text(value, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
