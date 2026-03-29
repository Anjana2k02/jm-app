-- ─── Song metadata columns ────────────────────────────────────────────────────
-- Run this against your Supabase project to add song type, Key, BPM, and
-- Duration fields to the documents table.  Safe to run multiple times.

ALTER TABLE documents
  ADD COLUMN IF NOT EXISTS song_type        TEXT    NOT NULL DEFAULT 'song',
  ADD COLUMN IF NOT EXISTS song_key         TEXT,
  ADD COLUMN IF NOT EXISTS bpm              INTEGER,
  ADD COLUMN IF NOT EXISTS duration_seconds INTEGER;

-- Constrain song_type to known values.
ALTER TABLE documents
  DROP CONSTRAINT IF EXISTS chk_song_type;
ALTER TABLE documents
  ADD CONSTRAINT chk_song_type CHECK (song_type IN ('song', 'medley'));

-- Optional: add check constraints for sensible value ranges.
-- ALTER TABLE documents ADD CONSTRAINT chk_bpm CHECK (bpm IS NULL OR bpm > 0);
-- ALTER TABLE documents ADD CONSTRAINT chk_duration CHECK (duration_seconds IS NULL OR duration_seconds >= 0);
