-- Reactions and flat (non-threaded) comments on posts. Visibility inherits
-- from the parent post via are_friends(), matching the pattern already used
-- by post_media/post_exercise/etc. in 0001_init.sql.

create table public.post_reactions (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  reaction text not null check (reaction in ('fire', 'flex', 'clap', 'trophy', 'heart')),
  created_at timestamptz not null default now(),
  unique (post_id, user_id, reaction)
);

alter table public.post_reactions enable row level security;

create index post_reactions_post_id_idx on public.post_reactions (post_id);

create table public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);

alter table public.post_comments enable row level security;

create index post_comments_post_id_idx on public.post_comments (post_id);

-- post_reactions RLS
create policy "post_reactions_select_via_post"
  on public.post_reactions for select
  using (exists (
    select 1 from public.posts p
    where p.id = post_id
      and (p.user_id = auth.uid() or public.are_friends(auth.uid(), p.user_id))
  ));

create policy "post_reactions_insert_self"
  on public.post_reactions for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.posts p
      where p.id = post_id
        and (p.user_id = auth.uid() or public.are_friends(auth.uid(), p.user_id))
    )
  );

create policy "post_reactions_delete_self"
  on public.post_reactions for delete
  using (user_id = auth.uid());

-- post_comments RLS
create policy "post_comments_select_via_post"
  on public.post_comments for select
  using (exists (
    select 1 from public.posts p
    where p.id = post_id
      and (p.user_id = auth.uid() or public.are_friends(auth.uid(), p.user_id))
  ));

create policy "post_comments_insert_self"
  on public.post_comments for insert
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.posts p
      where p.id = post_id
        and (p.user_id = auth.uid() or public.are_friends(auth.uid(), p.user_id))
    )
  );

create policy "post_comments_delete_self"
  on public.post_comments for delete
  using (user_id = auth.uid());
