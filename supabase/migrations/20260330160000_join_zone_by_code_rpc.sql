-- Join zone by scanned/manual code.
-- - Validates active zone by `zones.code`
-- - Marks membership active for current user in `zone_members`
-- - Returns zone payload consumed by app session/navigation

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

  insert into public.zone_members (
    zone_id,
    user_id,
    is_active,
    joined_at,
    updated_at
  )
  values (
    v_zone_id,
    v_user_id,
    true,
    now(),
    now()
  )
  on conflict (zone_id, user_id)
  do update
  set is_active = true,
      updated_at = now();

  select count(*)
    into v_active_count
  from public.zone_members zm
  where zm.zone_id = v_zone_id
    and zm.is_active = true;

  return jsonb_build_object(
    'id', v_zone_id,
    'code', v_code,
    'name', coalesce(v_name, 'Zone'),
    'city', v_city,
    'imageUrl', v_image_url,
    'lat', v_lat,
    'lng', v_lng,
    'activeCount', coalesce(v_active_count, 0)
  );
end;
$$;

grant execute on function public.join_zone_by_code(text) to authenticated;

