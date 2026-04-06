-- Links the 100 bulk-seeded users (seed_100_profiles_with_photos) to every active zone.
-- Same UUID namespace + name pattern as 20260405120000_seed_100_profiles_with_photos.sql
-- Idempotent: ON CONFLICT updates is_active + updated_at.

create extension if not exists "uuid-ossp";

insert into public.zone_members (zone_id, user_id, is_active, joined_at, updated_at)
select
  z.id,
  u.uid,
  true,
  now(),
  now()
from public.zones z
cross join (
  select uuid_generate_v5(
    'c0000000-0000-5000-8000-000000000001'::uuid,
    'sayhi-profile-bulk-v1-' || gs::text
  ) as uid
  from generate_series(1, 100) gs
) u
on conflict (zone_id, user_id) do update set
  is_active = true,
  updated_at = now();
