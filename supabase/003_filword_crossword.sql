-- Филворд ва кроссворди 15×15
create table if not exists public.filword_puzzles (
  id uuid primary key default gen_random_uuid(),
  title_tg text not null default 'Филворд',
  title_ru text not null default 'Филворд',
  grid_size int not null default 15 check (grid_size between 5 and 20),
  -- grid: array of strings, each length = grid_size (ҳарфҳо; холӣ = фосила)
  grid jsonb not null default '[]'::jsonb,
  -- words: ["ҚУРЪОН","ҚИБЛА",...]
  words jsonb not null default '[]'::jsonb,
  background_type text not null default 'none' check (background_type in ('none','image','video')),
  background_path text,
  status text not null default 'draft' check (status in ('draft','published','hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.filword_puzzles enable row level security;
drop policy if exists "public read published filwords" on public.filword_puzzles;
create policy "public read published filwords" on public.filword_puzzles
  for select to anon, authenticated using (status = 'published');
drop policy if exists "admins manage filwords" on public.filword_puzzles;
create policy "admins manage filwords" on public.filword_puzzles
  for all to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- Кроссворд: шабака + саволҳои рақамдор
alter table public.crossword_puzzles
  add column if not exists grid jsonb default '[]'::jsonb;
alter table public.crossword_puzzles
  add column if not exists background_type text default 'none';
alter table public.crossword_puzzles
  add column if not exists background_path text;
-- words format:
-- [{"num":1,"clue_tg":"...","clue_ru":"...","answer":"...","row":0,"col":0,"dir":"across"}]
