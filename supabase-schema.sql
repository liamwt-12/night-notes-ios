-- Night Notes Schema
-- This file documents the live schema the Swift app and Netlify function expect.
-- It does not run automatically.

-- ─────────────────────────────────────────
-- Profiles
-- ─────────────────────────────────────────

create table public.profiles (
  id                        uuid references auth.users on delete cascade primary key,
  email                     text,
  dreamer_type              text,
  subscription_active       boolean default false,
  free_interpretations_used int default 0,
  created_at                timestamptz default now()
);

-- ─────────────────────────────────────────
-- Dream Entries
-- ─────────────────────────────────────────

create table public.dream_entries (
  id            uuid default gen_random_uuid() primary key,
  user_id       uuid references public.profiles on delete cascade not null,
  raw_text      text not null,
  interpretation text,
  dreamer_type  text,
  symbols       text,
  created_at    timestamptz default now()
);

-- ─────────────────────────────────────────
-- Indexes
-- ─────────────────────────────────────────

create index dream_entries_user_id_idx on public.dream_entries(user_id);
create index dream_entries_created_at_idx on public.dream_entries(created_at desc);

-- ─────────────────────────────────────────
-- Row Level Security
-- ─────────────────────────────────────────

alter table public.profiles enable row level security;
alter table public.dream_entries enable row level security;

-- Profiles
create policy "Users view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Dream entries
create policy "Users view own dreams"
  on public.dream_entries for select
  using (auth.uid() = user_id);

create policy "Users insert own dreams"
  on public.dream_entries for insert
  with check (auth.uid() = user_id);

create policy "Users delete own dreams"
  on public.dream_entries for delete
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────
-- Auto-create profile on signup
-- ─────────────────────────────────────────

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, subscription_active, free_interpretations_used)
  values (new.id, new.email, false, 0);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
