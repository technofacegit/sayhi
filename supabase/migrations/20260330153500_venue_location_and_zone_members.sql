-- Venues: map/display fields
alter table public.venues
  add column if not exists image_url text,
  add column if not exists lat double precision,
  add column if not exists lng double precision;

-- Optional sanity checks for coordinates
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'venues_lat_range_check'
  ) then
    alter table public.venues
      add constraint venues_lat_range_check check (lat is null or (lat >= -90 and lat <= 90));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'venues_lng_range_check'
  ) then
    alter table public.venues
      add constraint venues_lng_range_check check (lng is null or (lng >= -180 and lng <= 180));
  end if;
end $$;

-- Zone membership / active user tracking
create table if not exists public.zone_members (
  zone_id uuid not null references public.zones(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  is_active boolean not null default true,
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (zone_id, user_id)
);

create index if not exists zone_members_zone_id_idx
  on public.zone_members(zone_id);

create index if not exists zone_members_active_idx
  on public.zone_members(zone_id, is_active);

-- RLS
alter table public.venues enable row level security;
alter table public.zone_members enable row level security;

drop policy if exists "venues_select_all" on public.venues;
create policy "venues_select_all"
on public.venues
for select
using (true);

drop policy if exists "venues_write_authenticated" on public.venues;
create policy "venues_write_authenticated"
on public.venues
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

-- Members: read allowed (active counts are public in app)
drop policy if exists "zone_members_select_all" on public.zone_members;
create policy "zone_members_select_all"
on public.zone_members
for select
using (true);

-- Members: users can only manage their own membership row
drop policy if exists "zone_members_insert_own" on public.zone_members;
create policy "zone_members_insert_own"
on public.zone_members
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "zone_members_update_own" on public.zone_members;
create policy "zone_members_update_own"
on public.zone_members
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "zone_members_delete_own" on public.zone_members;
create policy "zone_members_delete_own"
on public.zone_members
for delete
to authenticated
using (auth.uid() = user_id);

