-- Orphan public.profiles rows (no matching auth.users) break profile_interactions.target_id FK
-- and should never appear in discovery. Remove them so only real accounts remain.

delete from public.profiles p
where not exists (
  select 1
  from auth.users u
  where u.id = p.id
);
