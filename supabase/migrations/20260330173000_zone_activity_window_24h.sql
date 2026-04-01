-- 24-hour activity window for zone memberships.
-- A zone membership is active only within 24 hours from latest join/update.

drop function if exists public.get_recent_zones_for_current_user(integer);
drop function if exists public.get_current_active_zone_for_current_user();

create or replace function public.join_zone_by_code(input_code text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid;
  v_zone_id uuid;
  v_code text;
  v_name text;
  v_city text;
  v_image_url text;
  v_lat double precision;
  v_lng double precision;
  v_last_seen_at timestamptz;
  v_active_count integer;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  select
    z.id,
    z.code,
    v.name,
    v.city,
    v.image_url,
    v.lat,
    v.lng
  into
    v_zone_id,
    v_code,
    v_name,
    v_city,
    v_image_url,
    v_lat,
    v_lng
  from public.zones z
  left join public.venues v on v.id = z.venue_id
  where coalesce(z.is_active, true) = true
    and upper(trim(z.code)) = upper(trim(input_code))
  limit 1;

  if v_zone_id is null then
    raise exception 'INVALID_ZONE_CODE'
      using errcode = 'P0001';
  end if;

  v_last_seen_at := now();

  insert into public.zone_members (zone_id, user_id, is_active, joined_at, updated_at)
  values (v_zone_id, v_user_id, true, v_last_seen_at, v_last_seen_at)
  on conflict (zone_id, user_id)
  do update
  set is_active = true,
      updated_at = excluded.updated_at;

  select count(*)::integer
    into v_active_count
  from public.zone_members zm
  where zm.zone_id = v_zone_id
    and zm.is_active = true
    and zm.updated_at >= now() - interval '24 hours';

  return jsonb_build_object(
    'id', v_zone_id,
    'code', v_code,
    'name', coalesce(v_name, 'Zone'),
    'city', v_city,
    'imageUrl', v_image_url,
    'lat', v_lat,
    'lng', v_lng,
    'activeCount', coalesce(v_active_count, 0),
    'lastSeenAt', v_last_seen_at
  );
end;
$$;

grant execute on function public.join_zone_by_code(text) to authenticated;

create or replace function public.join_zone_by_id_and_code(
  input_zone_id uuid,
  input_code text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid;
  v_zone_id uuid;
  v_code text;
  v_name text;
  v_city text;
  v_image_url text;
  v_lat double precision;
  v_lng double precision;
  v_last_seen_at timestamptz;
  v_active_count integer;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = 'P0001';
  end if;

  select
    z.id,
    z.code,
    v.name,
    v.city,
    v.image_url,
    v.lat,
    v.lng
  into
    v_zone_id,
    v_code,
    v_name,
    v_city,
    v_image_url,
    v_lat,
    v_lng
  from public.zones z
  left join public.venues v on v.id = z.venue_id
  where z.id = input_zone_id
    and coalesce(z.is_active, true) = true
    and upper(trim(z.code)) = upper(trim(input_code))
  limit 1;

  if v_zone_id is null then
    raise exception 'ZONE_CODE_MISMATCH'
      using errcode = 'P0001';
  end if;

  v_last_seen_at := now();

  insert into public.zone_members (zone_id, user_id, is_active, joined_at, updated_at)
  values (v_zone_id, v_user_id, true, v_last_seen_at, v_last_seen_at)
  on conflict (zone_id, user_id)
  do update
  set is_active = true,
      updated_at = excluded.updated_at;

  select count(*)::integer
    into v_active_count
  from public.zone_members zm
  where zm.zone_id = v_zone_id
    and zm.is_active = true
    and zm.updated_at >= now() - interval '24 hours';

  return jsonb_build_object(
    'id', v_zone_id,
    'code', v_code,
    'name', coalesce(v_name, 'Zone'),
    'city', v_city,
    'imageUrl', v_image_url,
    'lat', v_lat,
    'lng', v_lng,
    'activeCount', coalesce(v_active_count, 0),
    'lastSeenAt', v_last_seen_at
  );
end;
$$;

grant execute on function public.join_zone_by_id_and_code(uuid, text) to authenticated;

create or replace function public.get_recent_zones_for_current_user(
  limit_count integer default 5
)
returns table (
  id uuid,
  code text,
  name text,
  city text,
  image_url text,
  lat double precision,
  lng double precision,
  active_count integer,
  last_seen_at timestamptz,
  active_until timestamptz,
  is_active_now boolean
)
language sql
stable
security definer
set search_path = public, auth
as $$
  with recent as (
    select
      zm.zone_id,
      max(zm.updated_at) as last_seen_at
    from public.zone_members zm
    where zm.user_id = auth.uid()
    group by zm.zone_id
    order by max(zm.updated_at) desc
    limit greatest(limit_count, 1)
  )
  select
    z.id,
    z.code,
    coalesce(v.name, 'Zone') as name,
    v.city,
    v.image_url,
    v.lat,
    v.lng,
    (
      select count(*)::integer
      from public.zone_members zm2
      where zm2.zone_id = z.id
        and zm2.is_active = true
        and zm2.updated_at >= now() - interval '24 hours'
    ) as active_count,
    r.last_seen_at,
    r.last_seen_at + interval '24 hours' as active_until,
    (r.last_seen_at + interval '24 hours' > now()) as is_active_now
  from recent r
  join public.zones z on z.id = r.zone_id
  left join public.venues v on v.id = z.venue_id
  order by r.last_seen_at desc;
$$;

grant execute on function public.get_recent_zones_for_current_user(integer) to authenticated;

create or replace function public.get_current_active_zone_for_current_user()
returns table (
  id uuid,
  code text,
  name text,
  city text,
  image_url text,
  lat double precision,
  lng double precision,
  active_count integer,
  last_seen_at timestamptz,
  active_until timestamptz,
  is_active_now boolean
)
language sql
stable
security definer
set search_path = public, auth
as $$
  with mine as (
    select
      zm.zone_id,
      max(zm.updated_at) as last_seen_at
    from public.zone_members zm
    where zm.user_id = auth.uid()
      and zm.is_active = true
    group by zm.zone_id
    order by max(zm.updated_at) desc
    limit 1
  )
  select
    z.id,
    z.code,
    coalesce(v.name, 'Zone') as name,
    v.city,
    v.image_url,
    v.lat,
    v.lng,
    (
      select count(*)::integer
      from public.zone_members zm2
      where zm2.zone_id = z.id
        and zm2.is_active = true
        and zm2.updated_at >= now() - interval '24 hours'
    ) as active_count,
    m.last_seen_at,
    m.last_seen_at + interval '24 hours' as active_until,
    (m.last_seen_at + interval '24 hours' > now()) as is_active_now
  from mine m
  join public.zones z on z.id = m.zone_id
  left join public.venues v on v.id = z.venue_id
  where m.last_seen_at + interval '24 hours' > now()
  limit 1;
$$;

grant execute on function public.get_current_active_zone_for_current_user() to authenticated;
