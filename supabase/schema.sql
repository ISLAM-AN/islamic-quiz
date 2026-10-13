-- Илмхона admin schema starter. Review and test on a new Supabase project before production.
create extension if not exists pgcrypto;
create table if not exists public.admin_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin','editor')),
  created_at timestamptz not null default now()
);
create or replace function public.is_ilmkhona_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.admin_profiles p where p.user_id = auth.uid() and p.role in ('admin','editor')); $$;
revoke all on function public.is_ilmkhona_admin() from public;
grant execute on function public.is_ilmkhona_admin() to authenticated;

create table if not exists public.quiz_questions (
 id uuid primary key default gen_random_uuid(),
 question_tg text not null, question_ru text not null,
 category_tg text not null default '', category_ru text not null default '',
 options_tg jsonb not null check (jsonb_typeof(options_tg)='array' and jsonb_array_length(options_tg)=4),
 options_ru jsonb not null check (jsonb_typeof(options_ru)='array' and jsonb_array_length(options_ru)=4),
 correct_option text not null check (correct_option in ('A','B','C','D')),
 success_tg text not null default '', success_ru text not null default '',
 failure_tg text not null default '', failure_ru text not null default '',
 background_type text not null default 'image' check (background_type in ('image','video')),
 background_path text, published boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.islamic_books (
 id uuid primary key default gen_random_uuid(), title_tg text not null default '', title_ru text not null default '',
 author_tg text not null default '', author_ru text not null default '', description_tg text not null default '', description_ru text not null default '',
 book_language text not null default 'tg', pdf_path text, cover_path text, published boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.app_content (
 id uuid primary key default gen_random_uuid(), title_tg text not null default '', title_ru text not null default '',
 body_tg text not null default '', body_ru text not null default '', content_type text not null default 'announcement',
 published boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.install_events (
 install_id uuid primary key, first_seen_at timestamptz not null default now(), last_seen_at timestamptz not null default now(), app_version text
);

alter table public.admin_profiles enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.islamic_books enable row level security;
alter table public.app_content enable row level security;
alter table public.install_events enable row level security;
-- Admin/editor can manage rows. Public app reads published records only; do NOT expose correct_option directly in production.
create policy "admins manage profiles" on public.admin_profiles for all to authenticated using (public.is_ilmkhona_admin()) with check (public.is_ilmkhona_admin());
create policy "admins manage questions" on public.quiz_questions for all to authenticated using (public.is_ilmkhona_admin()) with check (public.is_ilmkhona_admin());
create policy "admins manage books" on public.islamic_books for all to authenticated using (public.is_ilmkhona_admin()) with check (public.is_ilmkhona_admin());
create policy "admins manage content" on public.app_content for all to authenticated using (public.is_ilmkhona_admin()) with check (public.is_ilmkhona_admin());
create policy "admins read install events" on public.install_events for select to authenticated using (public.is_ilmkhona_admin());
-- Do not add public INSERT/UPDATE policies for install_events until an edge function or rate-limited endpoint validates events.
-- Create private Storage buckets: question-media, islamic-books, content-media.
-- Add storage.objects policies allowing authenticated admins only, using public.is_ilmkhona_admin().
