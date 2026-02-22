/// Common formatting utilities used across screens.
///
/// Centralizes date formatting and other string formatting functions
/// to avoid duplication across the app.

/// Format a DateTime into a readable month + day string (e.g. "Jan 15").
String formatDateShort(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

/// Format a DateTime into a full readable date string (e.g. "Jan 15, 2026").
String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

/// Format duration in seconds to a readable string (e.g. "3m 45s").
String formatDuration(int seconds) {
  if (seconds <= 0) return '0s';
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  if (minutes == 0) return '${secs}s';
  if (secs == 0) return '${minutes}m';
  return '${minutes}m ${secs}s';
}
