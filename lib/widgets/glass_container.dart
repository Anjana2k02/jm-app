import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A container that renders a liquid-glass / glassmorphism surface.
///
/// When [kEnableGlass] is true it uses [BackdropFilter] with
/// [ImageFilter.blur] to blur the content underneath before applying a
/// semi-transparent tint and border.
///
/// When [enableBlur] is false (or [kEnableGlass] is false) it falls back to
/// an opaque surface using [kGlassFallbackDark] / [kGlassFallbackLight].
/// Use [enableBlur: false] for toolbars and inline bars where blur over live
/// content would be distracting.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.enableBlur = kEnableGlass,
    this.customBg,
    this.customBorder,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  /// Per-instance override of the global [kEnableGlass] switch.
  final bool enableBlur;

  /// Override the background tint colour (defaults to dark/light glass tokens).
  final Color? customBg;

  /// Override the border colour (defaults to dark/light glass tokens).
  final Color? customBorder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg =
        customBg ?? (isDark ? kGlassDarkBg : kGlassLightBg);
    final border =
        customBorder ?? (isDark ? kGlassDarkBorder : kGlassLightBorder);
    final fallback = isDark ? kGlassFallbackDark : kGlassFallbackLight;

    final decoration = BoxDecoration(
      color: enableBlur ? bg : fallback,
      borderRadius: borderRadius > 0
          ? BorderRadius.circular(borderRadius)
          : BorderRadius.zero,
      border: Border.all(color: border, width: 1.0),
    );

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (!enableBlur) return container;

    // ClipRRect must wrap BackdropFilter to prevent the blur from bleeding
    // outside the rounded corners.
    return ClipRRect(
      borderRadius: borderRadius > 0
          ? BorderRadius.circular(borderRadius)
          : BorderRadius.zero,
      child: BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: kGlassSigma, sigmaY: kGlassSigma),
        child: container,
      ),
    );
  }
}
