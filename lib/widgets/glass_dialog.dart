import 'dart:ui';
import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../theme/app_colors.dart';

// ─── Glass Dialog Helper ──────────────────────────────────────────────────────

/// Drop-in replacement for [showDialog] that wraps the dialog widget in a
/// [GlassContainer] so it receives the backdrop blur effect.
///
/// Usage — replace:
///   showDialog(context: context, builder: (ctx) => AlertDialog(...))
/// With:
///   showGlassDialog(context: context, builder: (ctx) => AlertDialog(...))
///
/// The [AlertDialog] must have [backgroundColor: Colors.transparent] so the
/// [GlassContainer] tint is visible. The [AppTheme.dialogTheme] already sets
/// this globally; set it explicitly on each dialog as well to be safe.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _GlassDialogWrapper(child: builder(ctx)),
  );
}

class _GlassDialogWrapper extends StatelessWidget {
  const _GlassDialogWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: child,
    );
  }
}

// ─── Glass Bottom Sheet Helper ────────────────────────────────────────────────

/// Drop-in replacement for [showModalBottomSheet] that adds the glass effect.
///
/// Usage — replace:
///   showModalBottomSheet(context: context, builder: (ctx) => ...)
/// With:
///   showGlassBottomSheet(context: context, builder: (ctx) => ...)
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: kGlassSigma,
            sigmaY: kGlassSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? kGlassDarkBg : kGlassLightBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark ? kGlassDarkBorder : kGlassLightBorder,
                  width: 1.0,
                ),
              ),
            ),
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

// ─── Glass SnackBar Helper ────────────────────────────────────────────────────

/// Shows a floating [SnackBar] with a liquid-glass background.
/// Use this instead of [ScaffoldMessenger.showSnackBar].
void showGlassSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      action: action,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? kGlassDarkBg : kGlassLightBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? kGlassDarkBorder : kGlassLightBorder,
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : kSeedPrimary,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
