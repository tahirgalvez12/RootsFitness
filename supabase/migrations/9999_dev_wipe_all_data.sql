-- ============================================================
-- DEV-ONLY: full wipe of all app data and auth users.
-- Run this manually in the Supabase SQL Editor when you want to
-- reset to a clean slate. NOT part of the normal migration chain —
-- numbered 9999 so it never runs automatically and is easy to spot.
--
-- This is IRREVERSIBLE. It deletes every row in every app table and
-- every auth user (so their emails become reusable for real signups).
-- ============================================================

-- Child tables first (though CASCADE from posts/profiles would also
-- get these, being explicit here makes the wipe order obvious).
delete from public.post_reactions;
delete from public.post_comments;
delete from public.post_media;
delete from public.post_exercise;
delete from public.post_weight;
delete from public.post_meal;
delete from public.posts;

delete from public.goals;
delete from public.friendships;
delete from public.profiles;

-- Deleting from auth.users cascades to profiles too (profiles.id
-- references auth.users.id on delete cascade), but profiles is
-- already cleared above; this removes the actual login accounts so
-- the same emails can be used to sign up fresh.
delete from auth.users;
