-- ============================================================
-- Shared workspace: every signed-in user can see and edit
-- ALL documents, templates, sessions, and setlists.
-- Run in the Supabase SQL editor. Replaces the old per-user
-- policies from supabase_schema.sql / supabase_sessions_schema.sql.
--
-- RLS stays ENABLED so the public/anon key still cannot read
-- anything — only authenticated users get access.
-- ============================================================

-- Drop the old owner-only policies (names from earlier scripts).
drop policy if exists "documents_select" on public.documents;
drop policy if exists "documents_insert" on public.documents;
drop policy if exists "documents_update" on public.documents;
drop policy if exists "documents_delete" on public.documents;
drop policy if exists "templates_select" on public.templates;
drop policy if exists "templates_insert" on public.templates;
drop policy if exists "templates_update" on public.templates;
drop policy if exists "templates_delete" on public.templates;
drop policy if exists "template_items_select" on public.template_items;
drop policy if exists "template_items_insert" on public.template_items;
drop policy if exists "template_items_update" on public.template_items;
drop policy if exists "template_items_delete" on public.template_items;
drop policy if exists "Users manage own sessions" on public.sessions;
drop policy if exists "Users manage own session songs" on public.session_songs;

-- Shared-workspace policies: any authenticated user, any row.
create policy "documents_shared" on public.documents
  for all to authenticated using (true) with check (true);
create policy "templates_shared" on public.templates
  for all to authenticated using (true) with check (true);
create policy "template_items_shared" on public.template_items
  for all to authenticated using (true) with check (true);
create policy "sessions_shared" on public.sessions
  for all to authenticated using (true) with check (true);
create policy "session_songs_shared" on public.session_songs
  for all to authenticated using (true) with check (true);

-- Make sure RLS is on and the role has table privileges.
alter table public.documents      enable row level security;
alter table public.templates      enable row level security;
alter table public.template_items enable row level security;
alter table public.sessions       enable row level security;
alter table public.session_songs  enable row level security;
grant all on public.documents, public.templates, public.template_items,
             public.sessions, public.session_songs to authenticated;

-- Verify: should list one *_shared policy per table.
select tablename, policyname, roles
from pg_policies
where schemaname = 'public'
order by tablename;
