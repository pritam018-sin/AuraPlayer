import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class FrostedGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? fillColor;
  final Color? borderColor;
  final double blur;
  final VoidCallback? onTap;

  const FrostedGlass({
    super.key,
    required this.child,
    this.borderRadius = 18.0,
    this.padding = const EdgeInsets.all(12.0),
    this.margin,
    this.fillColor,
    this.borderColor,
    this.blur = 36.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseColor = fillColor ?? (isLight ? AppTheme.lightSurface : AppTheme.glassFill);
    final defaultBorder = isLight ? AppTheme.lightGlassBorder : const Color(0x38FFFFFF);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLight
                  ? [
                      (fillColor ?? Colors.white).withValues(alpha: 0.32),
                      (fillColor ?? Colors.white).withValues(alpha: 0.12),
                    ]
                  : [
                      baseColor.withValues(alpha: 0.18),
                      baseColor.withValues(alpha: 0.06),
                    ],
            ),
            border: Border.all(
              color: borderColor ?? defaultBorder,
              width: 1.0,
            ),
            boxShadow: [
              // Deep ambient drop shadow
              BoxShadow(
                color: isLight
                    ? const Color(0xFF0F172A).withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
              // Specular top light refraction edge
              BoxShadow(
                color: Colors.white.withValues(alpha: isLight ? 0.40 : 0.08),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
              // Electric aura ambient glow
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
