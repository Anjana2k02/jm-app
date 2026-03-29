import 'package:flutter/services.dart';

/// Haptics feedback utility for different interaction types.
/// Provides a consistent haptic experience across the app.
class HapticsManager {
  /// Light tap feedback - quick, subtle
  /// Used for: button taps, list selections, small interactions
  static Future<void> lightTap() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Haptics not available on this device
    }
  }

  /// Medium feedback - noticeable but not jarring
  /// Used for: successful actions, dismissals, sidebar toggle
  static Future<void> mediumTap() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Strong feedback - pronounced reaction
  /// Used for: drag start/end, important confirmations, errors
  static Future<void> heavyTap() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Selection changed - used during drag/scroll operations
  /// Used for: reorder drag updates, scroll selection
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Long press detected feedback - indicates drag-to-reorder ready
  static Future<void> longPressFeedback() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Drag started feedback - strong indication drag has begun
  static Future<void> dragStartFeedback() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Continuous drag feedback during reorder
  static Future<void> dragContinuousFeedback() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Drag ended/dropped feedback
  static Future<void> dragEndFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Sidebar toggle feedback - smooth, medium intensity
  static Future<void> sidebarToggleFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Song selection feedback
  static Future<void> songSelectedFeedback() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Zoom feedback - light feedback for zoom in/out
  static Future<void> zoomFeedback() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Dismiss/swipe feedback
  static Future<void> dismissFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Error feedback - double pulse
  static Future<void> errorFeedback() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Success feedback - ascending pattern
  static Future<void> successFeedback() async {
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
