-- Supabase schema for Jammer Docs
-- Run in Supabase SQL editor.

create extension if not exists pgcrypto;

-- User roles
do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum ('admin', 'user');
  end if;
end $$;

create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role public.app_role not null default 'user',
  created_at timestamptz not null default now()
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  title text not null,
  content jsonb not null default '[]',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.template_items (
  template_id uuid not null references public.templates(id) on delete cascade,
  document_id uuid not null references public.documents(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  sort_order int not null default 0,
  primary key (template_id, document_id)
);

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.documents enable row level security;
alter table public.templates enable row level security;
alter table public.template_items enable row level security;
alter table public.user_profiles enable row level security;

-- Documents policies
drop policy if exists "documents_select" on public.documents;
create policy "documents_select" on public.documents
  for select using (auth.uid() = user_id);

drop policy if exists "documents_insert" on public.documents;
create policy "documents_insert" on public.documents
  for insert with check (auth.uid() = user_id);

drop policy if exists "documents_update" on public.documents;
create policy "documents_update" on public.documents
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "documents_delete" on public.documents;
create policy "documents_delete" on public.documents
  for delete using (auth.uid() = user_id);

-- Templates policies
drop policy if exists "templates_select" on public.templates;
create policy "templates_select" on public.templates
  for select using (auth.uid() = user_id);

drop policy if exists "templates_insert" on public.templates;
create policy "templates_insert" on public.templates
  for insert with check (auth.uid() = user_id);

drop policy if exists "templates_update" on public.templates;
create policy "templates_update" on public.templates
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "templates_delete" on public.templates;
create policy "templates_delete" on public.templates
  for delete using (auth.uid() = user_id);

-- Template items policies
drop policy if exists "template_items_select" on public.template_items;
create policy "template_items_select" on public.template_items
  for select using (auth.uid() = user_id);

drop policy if exists "template_items_insert" on public.template_items;
create policy "template_items_insert" on public.template_items
  for insert with check (auth.uid() = user_id);

drop policy if exists "template_items_update" on public.template_items;
create policy "template_items_update" on public.template_items
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "template_items_delete" on public.template_items;
create policy "template_items_delete" on public.template_items
  for delete using (auth.uid() = user_id);

-- User profiles policies
drop policy if exists "profiles_select" on public.user_profiles;
create policy "profiles_select" on public.user_profiles
  for select using (auth.uid() = user_id);

drop policy if exists "profiles_insert" on public.user_profiles;
create policy "profiles_insert" on public.user_profiles
  for insert with check (auth.uid() = user_id);

drop policy if exists "profiles_update" on public.user_profiles;
create policy "profiles_update" on public.user_profiles
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "profiles_delete" on public.user_profiles;
create policy "profiles_delete" on public.user_profiles
  for delete using (auth.uid() = user_id);
