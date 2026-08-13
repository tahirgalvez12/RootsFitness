-- Allows any authenticated user to look up any profile (needed to find
-- someone by username before you're friends, to send a friend request).
-- Additive: combines via OR with profiles_select_self_or_friend from
-- 0001_init.sql, so this only ever widens visibility, never narrows it.
--
-- Note: RLS is row-level, not column-level, so this exposes the full
-- profiles row (username, display_name, avatar_url) to any authenticated
-- user, not just username — equivalent to treating profiles like public
-- @handles.

create policy "profiles_select_any_authenticated"
  on public.profiles for select
  using (auth.role() = 'authenticated');
