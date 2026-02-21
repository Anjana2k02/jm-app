-- ============================================================
-- Jammer Docs: Sessions Schema
-- Run this in your Supabase SQL editor AFTER the base schema.
-- ============================================================

-- sessions: Practice/Jam sessions with a date and notes
CREATE TABLE sessions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name         text NOT NULL,
  session_date date,
  notes        text DEFAULT '',
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now()
);

ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own sessions" ON sessions
  FOR ALL USING (user_id = auth.uid());

-- session_songs: Ordered setlist linking sessions to documents (songs)
CREATE TABLE session_songs (
  session_id  uuid REFERENCES sessions(id) ON DELETE CASCADE,
  document_id uuid REFERENCES documents(id) ON DELETE CASCADE,
  user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  sort_order  integer DEFAULT 0,
  PRIMARY KEY (session_id, document_id)
);

ALTER TABLE session_songs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own session songs" ON session_songs
  FOR ALL USING (user_id = auth.uid());

-- Optional: auto-update sessions.updated_at on row change
CREATE OR REPLACE FUNCTION update_session_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sessions_updated_at
  BEFORE UPDATE ON sessions
  FOR EACH ROW EXECUTE FUNCTION update_session_timestamp();
