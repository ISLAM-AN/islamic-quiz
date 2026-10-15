-- Илмхона: migration пурра барои панели нав
-- Дар Supabase SQL Editor як бор иҷро кунед (пайи 001_admin_upgrade).

-- ─── Саволҳои мусобиқа vs оддӣ ─────────────────────────────────
alter table public.questions
  add column if not exists question_kind text not null default 'regular'
    check (question_kind in ('regular','competition'));
alter table public.questions
  add column if not exists option_count int not null default 4
    check (option_count between 3 and 4);
alter table public.questions
  add column if not exists background_path text;
alter table public.questions
  add column if not exists background_type text default 'none'
    check (background_type in ('none','image','video'));

-- ─── Дуоҳо ─────────────────────────────────────────────────────
create table if not exists public.duas (
  id uuid primary key default gen_random_uuid(),
  title_tg text not null,
  title_ru text not null default '',
  body_tg text not null,
  body_ru text not null default '',
  category_tg text default '',
  category_ru text default '',
  status text not null default 'draft' check (status in ('draft','published','hidden')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists duas_status_idx on public.duas(status, created_at desc);
alter table public.duas enable row level security;
drop policy if exists "public read published duas" on public.duas;
create policy "public read published duas" on public.duas
  for select to anon, authenticated using (status = 'published');
drop policy if exists "admins manage duas" on public.duas;
create policy "admins manage duas" on public.duas
  for all to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- ─── Бозиҳо: сканворд ──────────────────────────────────────────
create table if not exists public.scanword_puzzles (
  id uuid primary key default gen_random_uuid(),
  clue_tg text not null,
  clue_ru text not null default '',
  answer text not null,
  letter_count int generated always as (char_length(answer)) stored,
  status text not null default 'draft' check (status in ('draft','published','hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.scanword_puzzles enable row level security;
drop policy if exists "public read published scanwords" on public.scanword_puzzles;
create policy "public read published scanwords" on public.scanword_puzzles
  for select to anon, authenticated using (status = 'published');
drop policy if exists "admins manage scanwords" on public.scanword_puzzles;
create policy "admins manage scanwords" on public.scanword_puzzles
  for all to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- ─── Бозиҳо: кроссворд (калимаҳо бо мавқеъ) ────────────────────
create table if not exists public.crossword_puzzles (
  id uuid primary key default gen_random_uuid(),
  title_tg text not null default 'Кроссворд',
  title_ru text not null default 'Кроссворд',
  grid_size int not null default 10 check (grid_size between 5 and 20),
  words jsonb not null default '[]'::jsonb,
  -- words: [{"clue_tg":"...","clue_ru":"...","answer":"ҚУРЪОН","row":0,"col":0,"dir":"across|down"}]
  status text not null default 'draft' check (status in ('draft','published','hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.crossword_puzzles enable row level security;
drop policy if exists "public read published crosswords" on public.crossword_puzzles;
create policy "public read published crosswords" on public.crossword_puzzles
  for select to anon, authenticated using (status = 'published');
drop policy if exists "admins manage crosswords" on public.crossword_puzzles;
create policy "admins manage crosswords" on public.crossword_puzzles
  for all to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- ─── Мусобиқа ва ғолибон ───────────────────────────────────────
create table if not exists public.competitions (
  id uuid primary key default gen_random_uuid(),
  title_tg text not null,
  title_ru text not null default '',
  starts_at timestamptz,
  ends_at timestamptz,
  status text not null default 'draft' check (status in ('draft','active','finished','hidden')),
  created_at timestamptz not null default now()
);
alter table public.competitions enable row level security;
drop policy if exists "public read competitions" on public.competitions;
create policy "public read competitions" on public.competitions
  for select to anon, authenticated using (status in ('active','finished'));
drop policy if exists "admins manage competitions" on public.competitions;
create policy "admins manage competitions" on public.competitions
  for all to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

create table if not exists public.competition_scores (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid references public.competitions(id) on delete cascade,
  player_name text not null default 'Иштирокчӣ',
  install_id text,
  score int not null default 0,
  total int not null default 0,
  played_at timestamptz not null default now()
);
create index if not exists competition_scores_rank_idx
  on public.competition_scores(competition_id, score desc, played_at asc);
alter table public.competition_scores enable row level security;
drop policy if exists "public insert scores" on public.competition_scores;
create policy "public insert scores" on public.competition_scores
  for insert to anon, authenticated with check (true);
drop policy if exists "public read scores" on public.competition_scores;
create policy "public read scores" on public.competition_scores
  for select to anon, authenticated using (true);
drop policy if exists "admins manage scores" on public.competition_scores;
create policy "admins manage scores" on public.competition_scores
  for all to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- ─── Storage барои заминаи саволҳо (агар набошад) ───────────────
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('question-media', 'question-media', true, 20971520,
  array['image/jpeg','image/png','image/webp','video/mp4','video/webm'])
on conflict (id) do nothing;
