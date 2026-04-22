-- ═══════════════════════════════════════════════════════════════
-- Adventurer's Cookbook — Social Features Schema
-- Run this in Supabase → SQL Editor → New query
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Extend recipes table ────────────────────────────────────
alter table public.recipes
  add column if not exists visibility text not null default 'private'
    check (visibility in ('private', 'public'));

alter table public.recipes
  add column if not exists created_at timestamptz not null default now();

create index if not exists recipes_visibility_idx on public.recipes(visibility);

-- ── 2. Profiles (for showing who authored what) ────────────────
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles select" on public.profiles;
create policy "profiles select" on public.profiles
  for select using (auth.role() = 'authenticated');

drop policy if exists "profiles upsert own" on public.profiles;
create policy "profiles upsert own" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, split_part(new.email, '@', 1))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill profiles for existing users
insert into public.profiles (id, email, display_name)
select id, email, split_part(email, '@', 1) from auth.users
on conflict (id) do nothing;

-- ── 3. Collaborators ───────────────────────────────────────────
create table if not exists public.recipe_collaborators (
  recipe_id text references public.recipes(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  added_at timestamptz default now(),
  primary key (recipe_id, user_id)
);

alter table public.recipe_collaborators enable row level security;

-- SECURITY DEFINER helper funcs to break RLS recursion between recipes & collaborators
create or replace function public.user_owns_recipe(rid text)
returns boolean language sql security definer stable as $$
  select exists(select 1 from public.recipes where id = rid and user_id = auth.uid());
$$;

create or replace function public.user_collaborates_on(rid text)
returns boolean language sql security definer stable as $$
  select exists(select 1 from public.recipe_collaborators where recipe_id = rid and user_id = auth.uid());
$$;

grant execute on function public.user_owns_recipe(text) to authenticated;
grant execute on function public.user_collaborates_on(text) to authenticated;

drop policy if exists "collab select" on public.recipe_collaborators;
create policy "collab select" on public.recipe_collaborators
  for select using (
    auth.uid() = user_id or public.user_owns_recipe(recipe_id)
  );

drop policy if exists "collab insert owner" on public.recipe_collaborators;
create policy "collab insert owner" on public.recipe_collaborators
  for insert with check (public.user_owns_recipe(recipe_id));

drop policy if exists "collab delete owner" on public.recipe_collaborators;
create policy "collab delete owner" on public.recipe_collaborators
  for delete using (public.user_owns_recipe(recipe_id));

-- ── 4. Update recipes RLS to allow collaborators + public ──────
drop policy if exists "own recipes select" on public.recipes;
drop policy if exists "own recipes insert" on public.recipes;
drop policy if exists "own recipes update" on public.recipes;
drop policy if exists "own recipes delete" on public.recipes;
drop policy if exists "recipes select" on public.recipes;
drop policy if exists "recipes insert" on public.recipes;
drop policy if exists "recipes update" on public.recipes;
drop policy if exists "recipes delete" on public.recipes;

create policy "recipes select" on public.recipes
  for select using (
    auth.uid() = user_id
    or visibility = 'public'
    or public.user_collaborates_on(id)
  );

create policy "recipes insert" on public.recipes
  for insert with check (auth.uid() = user_id);

create policy "recipes update" on public.recipes
  for update using (
    auth.uid() = user_id or public.user_collaborates_on(id)
  ) with check (
    auth.uid() = user_id or public.user_collaborates_on(id)
  );

create policy "recipes delete" on public.recipes
  for delete using (auth.uid() = user_id);

-- ── 5. Ratings ─────────────────────────────────────────────────
create table if not exists public.recipe_ratings (
  recipe_id text references public.recipes(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  review text,
  updated_at timestamptz default now(),
  primary key (recipe_id, user_id)
);

alter table public.recipe_ratings enable row level security;

drop policy if exists "ratings select" on public.recipe_ratings;
create policy "ratings select" on public.recipe_ratings
  for select using (auth.role() = 'authenticated');

drop policy if exists "ratings insert" on public.recipe_ratings;
create policy "ratings insert" on public.recipe_ratings
  for insert with check (
    auth.uid() = user_id
    and not public.user_owns_recipe(recipe_id)
  );

drop policy if exists "ratings update" on public.recipe_ratings;
create policy "ratings update" on public.recipe_ratings
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "ratings delete" on public.recipe_ratings;
create policy "ratings delete" on public.recipe_ratings
  for delete using (auth.uid() = user_id);

-- ── Done! ──────────────────────────────────────────────────────
