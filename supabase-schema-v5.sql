-- ═══════════════════════════════════════════════════════════════
-- Adventurer's Cookbook — Follow + XP (v5)
-- Run in Supabase → SQL Editor → New query
-- ═══════════════════════════════════════════════════════════════

-- ── Follows ────────────────────────────────────────────────────
create table if not exists public.follows (
  follower_id uuid references auth.users(id) on delete cascade,
  followed_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (follower_id, followed_id),
  check (follower_id <> followed_id)
);

alter table public.follows enable row level security;

drop policy if exists "follows select" on public.follows;
create policy "follows select" on public.follows
  for select using (auth.role() = 'authenticated');

drop policy if exists "follows insert" on public.follows;
create policy "follows insert" on public.follows
  for insert with check (auth.uid() = follower_id);

drop policy if exists "follows delete" on public.follows;
create policy "follows delete" on public.follows
  for delete using (auth.uid() = follower_id);

create index if not exists follows_follower_idx on public.follows(follower_id);
create index if not exists follows_followed_idx on public.follows(followed_id);

-- ── XP ─────────────────────────────────────────────────────────
alter table public.profiles
  add column if not exists xp int not null default 0;

-- RPC for atomic XP increments
create or replace function public.award_xp(amount int)
returns int language plpgsql security definer set search_path = public as $$
declare new_xp int;
begin
  update public.profiles
    set xp = coalesce(xp, 0) + amount
    where id = auth.uid()
    returning xp into new_xp;
  return new_xp;
end;
$$;

grant execute on function public.award_xp(int) to authenticated;
