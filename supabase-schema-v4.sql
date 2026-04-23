-- ═══════════════════════════════════════════════════════════════
-- Adventurer's Cookbook — Chapters (v4)
-- Run in Supabase → SQL Editor → New query
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  sort_order int not null default 0,
  created_at timestamptz default now()
);

alter table public.chapters enable row level security;

drop policy if exists "own chapters" on public.chapters;
create policy "own chapters" on public.chapters for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists chapters_user_idx on public.chapters(user_id);

-- Per-user assignment: any recipe visible to a user can be filed into one of their chapters
create table if not exists public.recipe_chapter_assignments (
  user_id uuid not null references auth.users(id) on delete cascade,
  recipe_id text not null references public.recipes(id) on delete cascade,
  chapter_id uuid not null references public.chapters(id) on delete cascade,
  updated_at timestamptz default now(),
  primary key (user_id, recipe_id)
);

alter table public.recipe_chapter_assignments enable row level security;

drop policy if exists "own assignments" on public.recipe_chapter_assignments;
create policy "own assignments" on public.recipe_chapter_assignments for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists rca_user_idx on public.recipe_chapter_assignments(user_id);
create index if not exists rca_chapter_idx on public.recipe_chapter_assignments(chapter_id);
