import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class AboutModal extends StatelessWidget {
  const AboutModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => const AboutModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: FrostedGlass(
          borderRadius: 22,
          padding: const EdgeInsets.all(28),
          fillColor: AppTheme.surface.withValues(alpha: 0.94),
          borderColor: AppTheme.glassBorder,
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
                  style: AppTheme.display.copyWith(fontSize: 24, letterSpacing: 0.5),
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
                    color: AppTheme.surfaceSecondary.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Organization', 'AuraStudio Corporation'),
                      const Divider(color: AppTheme.glassBorder, height: 16),
                      _infoRow('Creator & Lead', 'Pritam'),
                      const Divider(color: AppTheme.glassBorder, height: 16),
                      _infoRow('Engine', 'libmpv-2 + Flutter D3D11 Native'),
                      const Divider(color: AppTheme.glassBorder, height: 16),
                      _infoRow('License', 'AuraStudio Software License'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  '© 2026 AuraStudio Corporation by Pritam.\nAll rights reserved. Powered by AuraStudio.',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption.copyWith(color: AppTheme.textTertiary, fontSize: 11, height: 1.4),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
        Text(value, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
