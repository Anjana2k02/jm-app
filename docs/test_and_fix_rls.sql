-- Comprehensive RLS disable and permission check
-- Run this in Supabase SQL editor

-- 1. Disable RLS on all tables
alter table public.documents disable row level security;
alter table public.templates disable row level security;
alter table public.template_items disable row level security;
alter table public.user_profiles disable row level security;

-- 2. Check if RLS is really disabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('documents', 'templates', 'template_items', 'user_profiles');

-- 3. Grant all permissions to authenticated users (just in case)
grant all on public.documents to authenticated;
grant all on public.templates to authenticated;
grant all on public.template_items to authenticated;
grant all on public.user_profiles to authenticated;

-- 4. Test auth.uid() to verify authentication works
select 
  auth.uid() as current_user_id,
  case when auth.uid() is null then 'NOT AUTHENTICATED' else 'AUTHENTICATED' end as status;
