-- Ilmkhoona Admin: run in Supabase SQL Editor as project owner.
-- Existing Auth, public.admins, public.questions and question-media are preserved.

alter table public.questions
  add column if not exists question_text_tg text,
  add column if not exists question_text_ru text,
  add column if not exists option_a_tg text,
  add column if not exists option_b_tg text,
  add column if not exists option_c_tg text,
  add column if not exists option_d_tg text,
  add column if not exists option_a_ru text,
  add column if not exists option_b_ru text,
  add column if not exists option_c_ru text,
  add column if not exists option_d_ru text,
  add column if not exists success_message_tg text,
  add column if not exists success_message_ru text,
  add column if not exists failure_message_tg text,
  add column if not exists failure_message_ru text;

-- Migrate old Tajik-only records into the new Tajik columns.
update public.questions set
  question_text_tg = coalesce(question_text_tg, question_text),
  option_a_tg = coalesce(option_a_tg, option_a),
  option_b_tg = coalesce(option_b_tg, option_b),
  option_c_tg = coalesce(option_c_tg, option_c),
  option_d_tg = coalesce(option_d_tg, option_d),
  success_message_tg = coalesce(success_message_tg, success_message),
  failure_message_tg = coalesce(failure_message_tg, failure_message)
where question_text_tg is null or option_a_tg is null;

create table if not exists public.islamic_books (
  id uuid primary key default gen_random_uuid(),
  title_tg text not null,
  title_ru text not null,
  author text,
  category text,
  language text not null default 'tg' check (language in ('tg','ru','ar','multi')),
  description_tg text,
  description_ru text,
  pdf_path text not null,
  cover_path text,
  status text not null default 'draft' check (status in ('draft','published','hidden')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists islamic_books_status_created_idx on public.islamic_books(status, created_at desc);
alter table public.islamic_books enable row level security;
drop policy if exists "public read published islamic books" on public.islamic_books;
create policy "public read published islamic books" on public.islamic_books
  for select to anon, authenticated using (status = 'published');
drop policy if exists "admins manage islamic books" on public.islamic_books;
create policy "admins manage islamic books" on public.islamic_books
  for all to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- Installation telemetry: only counts app-reported installation IDs, not Play Store verified installs.
create table if not exists public.app_installations (
  install_id text primary key check (length(install_id) between 16 and 128),
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  app_version text,
  platform text not null default 'android' check (platform in ('android','other'))
);
alter table public.app_installations enable row level security;
drop policy if exists "admins read app installations" on public.app_installations;
create policy "admins read app installations" on public.app_installations
  for select to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()));
drop policy if exists "app can register installation id" on public.app_installations;
create policy "app can register installation id" on public.app_installations
  for insert to anon, authenticated
  with check (length(install_id) between 16 and 128 and platform = 'android');
drop policy if exists "app can update installation heartbeat" on public.app_installations;
create policy "app can update installation heartbeat" on public.app_installations
  for update to anon, authenticated
  using (true)
  with check (length(install_id) between 16 and 128 and platform = 'android');

-- PDF bucket is public-read for published book files; writes remain restricted to listed admins.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('islamic-books', 'islamic-books', true, 104857600, array['application/pdf','image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 104857600,
  allowed_mime_types = array['application/pdf','image/jpeg','image/png','image/webp'];

drop policy if exists "admins upload islamic book files" on storage.objects;
create policy "admins upload islamic book files" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'islamic-books' and exists (select 1 from public.admins a where a.user_id = auth.uid()));
drop policy if exists "admins update islamic book files" on storage.objects;
create policy "admins update islamic book files" on storage.objects
  for update to authenticated
  using (bucket_id = 'islamic-books' and exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (bucket_id = 'islamic-books' and exists (select 1 from public.admins a where a.user_id = auth.uid()));
drop policy if exists "admins delete islamic book files" on storage.objects;
create policy "admins delete islamic book files" on storage.objects
  for delete to authenticated
  using (bucket_id = 'islamic-books' and exists (select 1 from public.admins a where a.user_id = auth.uid()));
