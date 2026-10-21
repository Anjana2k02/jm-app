-- ============================================================
-- Reassign existing library data to your current login account
-- Run in the Supabase SQL editor.
--
-- Why: all 41 documents (songs/medleys) were created under the
-- old account 323ba17b-737c-4ec5-bc0c-c9a8cabe69bd. The account
-- you now sign in with (created 2026-09-21, the only row in
-- user_profiles) is d9170011-89b6-4035-8cc7-78bd5966969b.
-- Both apps fetch rows with user_id = <logged-in user>, so the
-- new account sees an empty library even though the data exists.
-- ============================================================

-- 0. Sanity check: confirm the two accounts and who owns what.
select id, email, created_at from auth.users order by created_at;
select user_id, count(*) as docs from public.documents group by user_id;

-- 1. Reassign everything from the old account to the new one.
--    (Tables other than documents are updated too in case they
--    hold rows hidden from the dashboard by RLS.)
do $$
declare
  old_id uuid := '323ba17b-737c-4ec5-bc0c-c9a8cabe69bd';
  new_id uuid := 'd9170011-89b6-4035-8cc7-78bd5966969b';
begin
  update public.documents      set user_id = new_id where user_id = old_id;
  update public.templates      set user_id = new_id where user_id = old_id;
  update public.template_items set user_id = new_id where user_id = old_id;
  update public.sessions       set user_id = new_id where user_id = old_id;
  update public.session_songs  set user_id = new_id where user_id = old_id;
end $$;

-- 2. Verify: every document should now belong to the new account.
select user_id, count(*) as docs from public.documents group by user_id;

-- ============================================================
-- Rollback (only if needed): swap the two ids above and re-run
-- the do-block, i.e. old_id := 'd9170011-...', new_id := '323ba17b-...'.
-- ============================================================

-- 3. RECOMMENDED after migration: re-enable row level security.
--    It was disabled earlier for debugging (docs/disable_rls.sql),
--    which currently lets anyone with the publishable key read and
--    write your tables. The policies from docs/supabase_schema.sql
--    are still in place, so simply re-enable RLS:
-- alter table public.documents      enable row level security;
-- alter table public.templates      enable row level security;
-- alter table public.template_items enable row level security;
-- alter table public.user_profiles  enable row level security;
