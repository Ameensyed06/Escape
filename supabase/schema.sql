-- ESCAPE — Supabase schema
-- Run this in your Supabase project's SQL Editor (Database > SQL Editor > New query).
-- Safe to re-run: every statement is guarded with IF NOT EXISTS / OR REPLACE / DROP-then-CREATE for policies.

-- =========================================================================
-- 1. PROFILES — required for the auth flow (sign up / sign in / Google)
-- =========================================================================
-- One row per auth.users row, auto-created on sign-up via trigger below.
-- Holds the display name shown in the app and per-user settings.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  email text not null default '',
  haptics_enabled boolean not null default true,
  notifications_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

-- Auto-create a profile row whenever someone signs up (email/password or Google).
-- Pulls "display_name" from the signup metadata the app sends, or falls back
-- to the part of the email before the @ sign.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, email)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(new.email, '@', 1)
    ),
    coalesce(new.email, '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =========================================================================
-- 2. APP DATA (reference schema for future cloud sync)
-- =========================================================================
-- The app currently keeps goals / workouts / blocked apps / friends on-device
-- (shared_preferences). These tables are NOT wired up to the app yet — they're
-- here so the schema is ready when/if you want cross-device sync. Every table
-- is scoped to auth.uid() via RLS so each user only ever sees their own rows.

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  target text not null default '',
  icon_key text not null default 'target',
  scheduled_minutes int,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.goal_completions (
  goal_id uuid not null references public.goals (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  completed_date date not null,
  primary key (goal_id, completed_date)
);

create table if not exists public.blocked_apps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  icon_key text not null default 'browser',
  package_name text,
  blocked boolean not null default true,
  minutes_saved_today int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.workout_days (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  weekday int not null check (weekday between 1 and 7),
  title text not null,
  unique (user_id, weekday)
);

create table if not exists public.routine_exercises (
  id uuid primary key default gen_random_uuid(),
  workout_day_id uuid not null references public.workout_days (id) on delete cascade,
  name text not null,
  target_sets int not null default 3,
  target_reps int not null default 10,
  tags text[] not null default '{}',
  last_weight numeric,
  last_reps int,
  sort_order int not null default 0
);

create table if not exists public.exercise_set_logs (
  id uuid primary key default gen_random_uuid(),
  exercise_id uuid not null references public.routine_exercises (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  log_date date not null default current_date,
  set_index int not null,
  weight numeric not null default 0,
  reps int not null default 0,
  done boolean not null default false
);

create table if not exists public.user_stats (
  user_id uuid primary key references auth.users (id) on delete cascade,
  focus_minutes_total int not null default 0,
  streak_days int not null default 0,
  total_volume numeric not null default 0,
  last_focus_date date,
  last_streak_date date
);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  friend_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'accepted' check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  unique (user_id, friend_id)
);

create table if not exists public.friend_codes (
  user_id uuid primary key references auth.users (id) on delete cascade,
  code text not null unique
);

create table if not exists public.activity_feed (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null check (type in ('workout', 'focus', 'streak')),
  message text not null,
  stat_label text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.activity_kudos (
  activity_id uuid not null references public.activity_feed (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (activity_id, user_id)
);

-- Row Level Security: every table is "owner reads/writes own rows".
-- (friendships/activity_feed additionally allow friends to read, see below.)

alter table public.goals enable row level security;
alter table public.goal_completions enable row level security;
alter table public.blocked_apps enable row level security;
alter table public.workout_days enable row level security;
alter table public.routine_exercises enable row level security;
alter table public.exercise_set_logs enable row level security;
alter table public.user_stats enable row level security;
alter table public.friendships enable row level security;
alter table public.friend_codes enable row level security;
alter table public.activity_feed enable row level security;
alter table public.activity_kudos enable row level security;

drop policy if exists "goals_owner" on public.goals;
create policy "goals_owner" on public.goals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "goal_completions_owner" on public.goal_completions;
create policy "goal_completions_owner" on public.goal_completions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "blocked_apps_owner" on public.blocked_apps;
create policy "blocked_apps_owner" on public.blocked_apps for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "workout_days_owner" on public.workout_days;
create policy "workout_days_owner" on public.workout_days for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "routine_exercises_owner" on public.routine_exercises;
create policy "routine_exercises_owner" on public.routine_exercises for all using (
  exists (select 1 from public.workout_days d where d.id = workout_day_id and d.user_id = auth.uid())
) with check (
  exists (select 1 from public.workout_days d where d.id = workout_day_id and d.user_id = auth.uid())
);

drop policy if exists "exercise_set_logs_owner" on public.exercise_set_logs;
create policy "exercise_set_logs_owner" on public.exercise_set_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "user_stats_owner" on public.user_stats;
create policy "user_stats_owner" on public.user_stats for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "friendships_owner" on public.friendships;
create policy "friendships_owner" on public.friendships for all using (auth.uid() = user_id or auth.uid() = friend_id) with check (auth.uid() = user_id);

drop policy if exists "friend_codes_owner_write" on public.friend_codes;
create policy "friend_codes_owner_write" on public.friend_codes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "friend_codes_read_any" on public.friend_codes;
create policy "friend_codes_read_any" on public.friend_codes for select using (true);

drop policy if exists "activity_feed_owner_write" on public.activity_feed;
create policy "activity_feed_owner_write" on public.activity_feed for insert with check (auth.uid() = user_id);

drop policy if exists "activity_feed_friends_read" on public.activity_feed;
create policy "activity_feed_friends_read" on public.activity_feed for select using (
  auth.uid() = user_id
  or exists (
    select 1 from public.friendships f
    where f.friend_id = activity_feed.user_id and f.user_id = auth.uid() and f.status = 'accepted'
  )
);

drop policy if exists "activity_kudos_owner" on public.activity_kudos;
create policy "activity_kudos_owner" on public.activity_kudos for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
