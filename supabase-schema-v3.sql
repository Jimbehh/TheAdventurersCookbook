-- ═══════════════════════════════════════════════════════════════
-- Adventurer's Cookbook — Favourites (v3)
-- Run in Supabase → SQL Editor → New query
-- ═══════════════════════════════════════════════════════════════

create table if not exists public.favourites (
  user_id uuid references auth.users(id) on delete cascade,
  recipe_id text references public.recipes(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, recipe_id)
);

alter table public.favourites enable row level security;

drop policy if exists "favourites select" on public.favourites;
create policy "favourites select" on public.favourites
  for select using (auth.uid() = user_id);

drop policy if exists "favourites insert" on public.favourites;
create policy "favourites insert" on public.favourites
  for insert with check (auth.uid() = user_id);

drop policy if exists "favourites delete" on public.favourites;
create policy "favourites delete" on public.favourites
  for delete using (auth.uid() = user_id);

create index if not exists favourites_user_idx on public.favourites(user_id);
