-- RootsFitness initial schema: profiles, friendships, goals, posts + friends-only RLS.
-- Run this whole file once in the Supabase SQL editor (SQL Editor > New query > paste > Run).

-- ============================================================
-- Extensions
-- ============================================================
create extension if not exists "pgcrypto";

-- ============================================================
-- profiles
-- ============================================================
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- ============================================================
-- friendships
-- Acceptance is modeled as two accepted rows (one per direction) so every
-- other table's RLS policy can do a single symmetric join instead of an
-- OR'd pair of asymmetric lookups.
-- ============================================================
create table public.friendships (
  user_id uuid not null references public.profiles (id) on delete cascade,
  friend_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  constraint friendships_no_self check (user_id <> friend_id)
);

alter table public.friendships enable row level security;

create index friendships_friend_id_idx on public.friendships (friend_id);

-- Helper: are two users accepted friends? Used throughout RLS policies below.
create or replace function public.are_friends(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.friendships
    where user_id = a and friend_id = b and status = 'accepted'
  );
$$;

-- Accept a pending request sent *to* the current user by `requester`.
-- Inserts the reciprocal row and flips the original to accepted.
create or replace function public.accept_friend_request(requester uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.friendships
    set status = 'accepted'
    where user_id = requester and friend_id = auth.uid() and status = 'pending';

  if not found then
    raise exception 'No pending friend request from % to current user', requester;
  end if;

  insert into public.friendships (user_id, friend_id, status)
  values (auth.uid(), requester, 'accepted')
  on conflict (user_id, friend_id) do update set status = 'accepted';
end;
$$;

-- ============================================================
-- goals
-- ============================================================
create table public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null check (type in ('lose_weight', 'bulk', 'general_fitness')),
  target_value numeric,
  target_date date,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.goals enable row level security;

create index goals_user_id_idx on public.goals (user_id);

-- ============================================================
-- posts + type-specific child tables
-- ============================================================
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null check (type in ('exercise', 'weight', 'meal', 'progress_pic')),
  caption text,
  created_at timestamptz not null default now()
);

alter table public.posts enable row level security;

create index posts_user_id_created_at_idx on public.posts (user_id, created_at desc);

create table public.post_exercise (
  post_id uuid primary key references public.posts (id) on delete cascade,
  activity_type text not null,
  duration_minutes integer,
  calories_burned integer,
  source text not null default 'manual' check (source in ('manual', 'healthkit')),
  healthkit_uuid text
);

alter table public.post_exercise enable row level security;

create table public.post_weight (
  post_id uuid primary key references public.posts (id) on delete cascade,
  weight_value numeric not null,
  unit text not null default 'lb' check (unit in ('lb', 'kg'))
);

alter table public.post_weight enable row level security;

create table public.post_meal (
  post_id uuid primary key references public.posts (id) on delete cascade,
  meal_name text,
  calories integer,
  protein_g numeric,
  carbs_g numeric,
  fat_g numeric
);

alter table public.post_meal enable row level security;

create table public.post_media (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  storage_path text not null,
  position integer not null default 0
);

alter table public.post_media enable row level security;

create index post_media_post_id_idx on public.post_media (post_id);

-- ============================================================
-- RLS policies
-- ============================================================

-- profiles: self + accepted friends can read; only self can write.
create policy "profiles_select_self_or_friend"
  on public.profiles for select
  using (id = auth.uid() or public.are_friends(auth.uid(), id));

create policy "profiles_insert_self"
  on public.profiles for insert
  with check (id = auth.uid());

create policy "profiles_update_self"
  on public.profiles for update
  using (id = auth.uid());

-- friendships: see rows you're a party to; only insert as the requester.
create policy "friendships_select_participant"
  on public.friendships for select
  using (user_id = auth.uid() or friend_id = auth.uid());

create policy "friendships_insert_as_requester"
  on public.friendships for insert
  with check (user_id = auth.uid());

create policy "friendships_delete_participant"
  on public.friendships for delete
  using (user_id = auth.uid() or friend_id = auth.uid());

-- goals: self + accepted friends can read; only self can write.
create policy "goals_select_self_or_friend"
  on public.goals for select
  using (user_id = auth.uid() or public.are_friends(auth.uid(), user_id));

create policy "goals_insert_self"
  on public.goals for insert
  with check (user_id = auth.uid());

create policy "goals_update_self"
  on public.goals for update
  using (user_id = auth.uid());

create policy "goals_delete_self"
  on public.goals for delete
  using (user_id = auth.uid());

-- posts: self + accepted friends can read; only self can write.
create policy "posts_select_self_or_friend"
  on public.posts for select
  using (user_id = auth.uid() or public.are_friends(auth.uid(), user_id));

create policy "posts_insert_self"
  on public.posts for insert
  with check (user_id = auth.uid());

create policy "posts_update_self"
  on public.posts for update
  using (user_id = auth.uid());

create policy "posts_delete_self"
  on public.posts for delete
  using (user_id = auth.uid());

-- Child tables inherit visibility from their parent post via a join,
-- and writes are restricted to the parent post's owner.
create policy "post_exercise_select_via_post"
  on public.post_exercise for select
  using (exists (
    select 1 from public.posts p
    where p.id = post_id
      and (p.user_id = auth.uid() or public.are_friends(auth.uid(), p.user_id))
  ));

create policy "post_exercise_write_via_post"
  on public.post_exercise for all
  using (exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid()))
  with check (exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid()));

create policy "post_weight_select_via_post"
  on public.post_weight for select
  using (exists (
    select 1 from public.posts p
    where p.id = post_id
      and (p.user_id = auth.uid() or public.are_friends(auth.uid(), p.user_id))
  ));

create policy "post_weight_write_via_post"
  on public.post_weight for all
  using (exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid()))
  with check (exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid()));

create policy "post_meal_select_via_post"
  on public.post_meal for select
  using (exists (
    select 1 from public.posts p
    where p.id = post_id
      and (p.user_id = auth.uid() or public.are_friends(auth.uid(), p.user_id))
  ));

create policy "post_meal_write_via_post"
  on public.post_meal for all
  using (exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid()))
  with check (exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid()));

create policy "post_media_select_via_post"
  on public.post_media for select
  using (exists (
    select 1 from public.posts p
    where p.id = post_id
      and (p.user_id = auth.uid() or public.are_friends(auth.uid(), p.user_id))
  ));

create policy "post_media_write_via_post"
  on public.post_media for all
  using (exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid()))
  with check (exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid()));

-- ============================================================
-- Storage: private bucket for post media, gated by the same
-- self-or-friend rule via post_media -> posts join.
-- Paths are expected as `{user_id}/{filename}`.
-- ============================================================
insert into storage.buckets (id, name, public)
values ('post-media', 'post-media', false)
on conflict (id) do nothing;

create policy "post_media_storage_select_self_or_friend"
  on storage.objects for select
  using (
    bucket_id = 'post-media'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.are_friends(auth.uid(), ((storage.foldername(name))[1])::uuid)
    )
  );

create policy "post_media_storage_insert_self"
  on storage.objects for insert
  with check (
    bucket_id = 'post-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "post_media_storage_delete_self"
  on storage.objects for delete
  using (
    bucket_id = 'post-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
