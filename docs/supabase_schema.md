# Supabase schema

This app expects the following tables and storage bucket.

## Tables

### documents

- id uuid primary key default gen_random_uuid()
- user_id uuid not null references auth.users(id)
- title text not null
- content jsonb not null default '[]'
- created_at timestamptz not null default now()
- updated_at timestamptz not null default now()

### templates

- id uuid primary key default gen_random_uuid()
- user_id uuid not null references auth.users(id)
- name text not null
- created_at timestamptz not null default now()

### template_items

- template_id uuid not null references templates(id) on delete cascade
- document_id uuid not null references documents(id) on delete cascade
- user_id uuid not null references auth.users(id)
- sort_order int not null default 0
- primary key (template_id, document_id)

## Storage

Bucket: doc-images (public)

## Row level security (example)

Enable RLS on all tables and add policies:

- documents: user_id = auth.uid()
- templates: user_id = auth.uid()
- template_items: user_id = auth.uid()
