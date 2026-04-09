-- Reset all like/dislike/favorite records.
-- This clears every row from profile_interactions for all users.

delete from public.profile_interactions;
