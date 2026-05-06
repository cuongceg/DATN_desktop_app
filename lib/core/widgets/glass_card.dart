import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = GlassTheme.cardRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? GlassTheme.darkSurface : GlassTheme.lightSurface;
    final border  = isDark ? GlassTheme.darkBorder  : GlassTheme.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTheme.blurStrength,
            sigmaY: GlassTheme.blurStrength,
          ),
          child: Container(
            width: width,
            height: height,
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: border, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
