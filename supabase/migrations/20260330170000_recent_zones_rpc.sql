-- Returns recently visited zones for current user, with active member counts.

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
  last_seen_at timestamptz
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
    ) as active_count,
    r.last_seen_at
  from recent r
  join public.zones z on z.id = r.zone_id
  left join public.venues v on v.id = z.venue_id
  order by r.last_seen_at desc;
$$;

grant execute on function public.get_recent_zones_for_current_user(integer) to authenticated;

