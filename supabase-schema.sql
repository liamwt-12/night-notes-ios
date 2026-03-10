-- Night Notes Schema

create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  free_dreams_used int default 0,
  tokens int default 0,
  subscription_status text default 'none',
  subscription_expires_at timestamptz,
  created_at timestamptz default now()
);

create table public.dreams (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  content text not null,
  interpretation text,
  interpretation_mode text default 'surface',
  token_used boolean default false,
  created_at timestamptz default now()
);

create table public.token_purchases (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  tokens_added int not null,
  amount_paid decimal(10,2) not null,
  apple_transaction_id text,
  created_at timestamptz default now()
);

-- Indexes
create index dreams_user_id_idx on public.dreams(user_id);
create index dreams_created_at_idx on public.dreams(created_at desc);

-- RLS
alter table public.profiles enable row level security;
alter table public.dreams enable row level security;
alter table public.token_purchases enable row level security;

create policy "Users view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users view own dreams" on public.dreams for select using (auth.uid() = user_id);
create policy "Users insert own dreams" on public.dreams for insert with check (auth.uid() = user_id);
create policy "Users delete own dreams" on public.dreams for delete using (auth.uid() = user_id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Check if user can interpret
create or replace function public.can_interpret_dream(user_uuid uuid)
returns jsonb as $$
declare
  p record;
begin
  select * into p from public.profiles where id = user_uuid;
  if p.subscription_status = 'active' then return '{"allowed":true,"reason":"subscription"}'::jsonb; end if;
  if p.free_dreams_used < 1 then return '{"allowed":true,"reason":"free"}'::jsonb; end if;
  if p.tokens > 0 then return '{"allowed":true,"reason":"token"}'::jsonb; end if;
  return '{"allowed":false,"reason":"none"}'::jsonb;
end;
$$ language plpgsql security definer;

-- Use dream credit
create or replace function public.use_dream_credit(user_uuid uuid)
returns jsonb as $$
declare
  p record;
begin
  select * into p from public.profiles where id = user_uuid for update;
  if p.subscription_status = 'active' then return '{"success":true,"type":"subscription"}'::jsonb; end if;
  if p.free_dreams_used < 1 then
    update public.profiles set free_dreams_used = free_dreams_used + 1 where id = user_uuid;
    return '{"success":true,"type":"free"}'::jsonb;
  end if;
  if p.tokens > 0 then
    update public.profiles set tokens = tokens - 1 where id = user_uuid;
    return '{"success":true,"type":"token"}'::jsonb;
  end if;
  return '{"success":false,"type":"none"}'::jsonb;
end;
$$ language plpgsql security definer;

-- Add tokens after purchase
create or replace function public.add_tokens(user_uuid uuid, token_count int, amount decimal, transaction_id text)
returns void as $$
begin
  update public.profiles set tokens = tokens + token_count where id = user_uuid;
  insert into public.token_purchases (user_id, tokens_added, amount_paid, apple_transaction_id)
  values (user_uuid, token_count, amount, transaction_id);
end;
$$ language plpgsql security definer;

-- Activate subscription
create or replace function public.activate_subscription(user_uuid uuid, transaction_id text)
returns void as $$
begin
  update public.profiles set subscription_status = 'active', subscription_expires_at = now() + interval '1 month' where id = user_uuid;
end;
$$ language plpgsql security definer;
