-- ============================================================
-- Jammer App: Complete Sessions & Documents Integration Schema
-- Run this in your Supabase SQL editor
-- ============================================================

-- Create sessions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.sessions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name         text NOT NULL,
  session_date date,
  notes        text DEFAULT '',
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now()
);

-- Create session_songs junction table (setlist for each session)
CREATE TABLE IF NOT EXISTS public.session_songs (
  session_id  uuid NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  document_id uuid NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sort_order  integer DEFAULT 0,
  PRIMARY KEY (session_id, document_id)
);

-- Enable RLS on sessions
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

-- Enable RLS on session_songs
ALTER TABLE public.session_songs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Row Level Security Policies
-- ============================================================

-- Sessions: Users can view their own sessions
DROP POLICY IF EXISTS "sessions_select" ON public.sessions;
CREATE POLICY "sessions_select" ON public.sessions
  FOR SELECT USING (auth.uid() = user_id);

-- Sessions: Users can create sessions
DROP POLICY IF EXISTS "sessions_insert" ON public.sessions;
CREATE POLICY "sessions_insert" ON public.sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Sessions: Users can update their own sessions
DROP POLICY IF EXISTS "sessions_update" ON public.sessions;
CREATE POLICY "sessions_update" ON public.sessions
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Sessions: Users can delete their own sessions
DROP POLICY IF EXISTS "sessions_delete" ON public.sessions;
CREATE POLICY "sessions_delete" ON public.sessions
  FOR DELETE USING (auth.uid() = user_id);

-- Session Songs: Users can view their own session songs
DROP POLICY IF EXISTS "session_songs_select" ON public.session_songs;
CREATE POLICY "session_songs_select" ON public.session_songs
  FOR SELECT USING (auth.uid() = user_id);

-- Session Songs: Users can add songs to their sessions
DROP POLICY IF EXISTS "session_songs_insert" ON public.session_songs;
CREATE POLICY "session_songs_insert" ON public.session_songs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Session Songs: Users can update session song order
DROP POLICY IF EXISTS "session_songs_update" ON public.session_songs;
CREATE POLICY "session_songs_update" ON public.session_songs
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Session Songs: Users can remove songs from their sessions
DROP POLICY IF EXISTS "session_songs_delete" ON public.session_songs;
CREATE POLICY "session_songs_delete" ON public.session_songs
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- Triggers & Functions
-- ============================================================

-- Auto-update sessions.updated_at when modified
DROP TRIGGER IF EXISTS sessions_updated_at ON public.sessions;
DROP FUNCTION IF EXISTS public.update_session_timestamp();

CREATE OR REPLACE FUNCTION public.update_session_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sessions_updated_at
  BEFORE UPDATE ON public.sessions
  FOR EACH ROW 
  EXECUTE FUNCTION public.update_session_timestamp();

-- ============================================================
-- Indexes for Performance
-- ============================================================

-- Index sessions by user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON public.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_created_at ON public.sessions(created_at DESC);

-- Index session_songs for quick lookups
CREATE INDEX IF NOT EXISTS idx_session_songs_session_id ON public.session_songs(session_id);
CREATE INDEX IF NOT EXISTS idx_session_songs_document_id ON public.session_songs(document_id);
CREATE INDEX IF NOT EXISTS idx_session_songs_user_id ON public.session_songs(user_id);
