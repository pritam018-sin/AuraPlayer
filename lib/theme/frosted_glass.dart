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
    this.blur = 28.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = fillColor ?? AppTheme.glassFill;

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
              colors: [
                baseColor.withValues(alpha: 0.68),
                baseColor.withValues(alpha: 0.38),
              ],
            ),
            border: Border.all(
              color: borderColor ?? const Color(0x38FFFFFF),
              width: 1.1,
            ),
            boxShadow: [
              // Deep ambient drop shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 32,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
              // Specular top light refraction edge
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.07),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
              // Electric aura ambient glow
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.04),
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
