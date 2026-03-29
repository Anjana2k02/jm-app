import 'dart:async';

import 'package:flutter/material.dart';

import '../models/document_model.dart';
import 'glass_container.dart';

/// Compact bar for editing a song's Key, BPM and Duration.
///
/// Place it with [ValueKey(document.id)] so Flutter recreates the widget
/// (and its text controllers) whenever the selected song changes.
///
/// [onSave] receives a map of DB column names → values.
/// A `null` value means the field should be cleared.
class SongMetaBar extends StatefulWidget {
  const SongMetaBar({
    super.key,
    required this.document,
    required this.onSave,
  });

  final AppDocument document;
  final void Function(Map<String, dynamic>) onSave;

  @override
  State<SongMetaBar> createState() => _SongMetaBarState();
}

class _SongMetaBarState extends State<SongMetaBar> {
  late final TextEditingController _keyCtrl;
  late final TextEditingController _bpmCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _secCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final doc = widget.document;
    final m = doc.durationSeconds != null ? doc.durationSeconds! ~/ 60 : null;
    final s = doc.durationSeconds != null ? doc.durationSeconds! % 60 : null;
    _keyCtrl = TextEditingController(text: doc.songKey ?? '');
    _bpmCtrl = TextEditingController(text: doc.bpm?.toString() ?? '');
    _minCtrl = TextEditingController(text: m != null ? '$m' : '');
    _secCtrl = TextEditingController(text: s != null ? '$s' : '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _keyCtrl.dispose();
    _bpmCtrl.dispose();
    _minCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  void _save() {
    final key = _keyCtrl.text.trim();
    final bpm = int.tryParse(_bpmCtrl.text.trim());
    final min = int.tryParse(_minCtrl.text.trim()) ?? 0;
    final sec = (int.tryParse(_secCtrl.text.trim()) ?? 0).clamp(0, 59);
    final totalSec = min * 60 + sec;

    widget.onSave({
      'song_key': key.isEmpty ? null : key,
      'bpm': bpm,
      'duration_seconds': totalSec <= 0 ? null : totalSec,
    });
  }

  /// Pill-shaped container: `Label  [value field]`
  Widget _pillField({
    required ColorScheme cs,
    required String label,
    required TextEditingController ctrl,
    required double width,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: width,
            child: TextField(
              controller: ctrl,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textCapitalization: textCapitalization,
              keyboardType: keyboardType,
              autocorrect: false,
              enableSuggestions: false,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
              ),
              onChanged: (_) => _scheduleSave(),
              onSubmitted: (_) => _save(),
              onEditingComplete: _save,
            ),
          ),
        ],
      ),
    );
  }

  /// Standalone rounded-rect input box (used for minutes / seconds).
  Widget _numberBox({
    required ColorScheme cs,
    required TextEditingController ctrl,
    required double width,
  }) {
    return Container(
      width: width,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: TextField(
        controller: ctrl,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        keyboardType: TextInputType.number,
        autocorrect: false,
        enableSuggestions: false,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 2),
        ),
        onChanged: (_) => _scheduleSave(),
        onSubmitted: (_) => _save(),
        onEditingComplete: _save,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassContainer(
      enableBlur: false,
      borderRadius: 0,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ── Key ─────────────────────────────────────────────────────────
          _pillField(
            cs: cs,
            label: 'Key',
            ctrl: _keyCtrl,
            width: 44,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(width: 10),

          // ── BPM ─────────────────────────────────────────────────────────
          _pillField(
            cs: cs,
            label: 'BPM',
            ctrl: _bpmCtrl,
            width: 40,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(width: 10),

          // ── Duration ─────────────────────────────────────────────────────
          Text(
            'Duration',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          _numberBox(cs: cs, ctrl: _minCtrl, width: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              'm',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          _numberBox(cs: cs, ctrl: _secCtrl, width: 36),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              's',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
