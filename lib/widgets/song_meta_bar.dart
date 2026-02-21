import 'dart:async';

import 'package:flutter/material.dart';

import '../models/document_model.dart';

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

  InputDecoration _fieldDeco(ColorScheme cs) => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.1),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        border: InputBorder.none,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          // Key
          Text(
            'Key',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _keyCtrl,
              style: const TextStyle(fontSize: 12),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              decoration: _fieldDeco(cs),
              onChanged: (_) => _scheduleSave(),
              onSubmitted: (_) => _save(),
              onEditingComplete: _save,
            ),
          ),

          const SizedBox(width: 16),

          // BPM
          Text(
            'BPM',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 58,
            child: TextField(
              controller: _bpmCtrl,
              style: const TextStyle(fontSize: 12),
              keyboardType: TextInputType.number,
              autocorrect: false,
              enableSuggestions: false,
              decoration: _fieldDeco(cs),
              onChanged: (_) => _scheduleSave(),
              onSubmitted: (_) => _save(),
              onEditingComplete: _save,
            ),
          ),

          const SizedBox(width: 16),

          // Duration
          Text(
            'Duration',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            child: TextField(
              controller: _minCtrl,
              style: const TextStyle(fontSize: 12),
              keyboardType: TextInputType.number,
              autocorrect: false,
              enableSuggestions: false,
              decoration: _fieldDeco(cs),
              onChanged: (_) => _scheduleSave(),
              onSubmitted: (_) => _save(),
              onEditingComplete: _save,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'm',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          SizedBox(
            width: 40,
            child: TextField(
              controller: _secCtrl,
              style: const TextStyle(fontSize: 12),
              keyboardType: TextInputType.number,
              autocorrect: false,
              enableSuggestions: false,
              decoration: _fieldDeco(cs),
              onChanged: (_) => _scheduleSave(),
              onSubmitted: (_) => _save(),
              onEditingComplete: _save,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
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
