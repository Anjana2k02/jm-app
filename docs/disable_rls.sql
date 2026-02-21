-- Temporary: Disable RLS for testing
-- Run this to disable RLS and test if the app works

alter table public.documents disable row level security;
alter table public.templates disable row level security;
alter table public.template_items disable row level security;
alter table public.user_profiles disable row level security;
