-- Discovery filters: country + distance; store user locations on profiles.

alter table public.profiles
  add column if not exists country text,
  add column if not exists lat double precision,
  add column if not exists lng double precision,
  add column if not exists location_updated_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_lat_range_ck'
  ) then
    alter table public.profiles
      add constraint profiles_lat_range_ck
      check (lat is null or (lat >= -90 and lat <= 90));
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_lng_range_ck'
  ) then
    alter table public.profiles
      add constraint profiles_lng_range_ck
      check (lng is null or (lng >= -180 and lng <= 180));
  end if;
end $$;

create index if not exists profiles_country_idx on public.profiles (lower(country));

alter table public.user_discovery_filters
  add column if not exists country text,
  add column if not exists max_distance_km integer;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'user_discovery_filters_distance_ck'
  ) then
    alter table public.user_discovery_filters
      add constraint user_discovery_filters_distance_ck
      check (
        max_distance_km is null
        or (max_distance_km between 1 and 500)
      );
  end if;
end $$;

drop function if exists public.get_discovery_profiles(int, text, int, int);

create or replace function public.get_discovery_profiles(
  p_limit int default 20,
  p_gender_filter text default null,
  p_min_age int default null,
  p_max_age int default null,
  p_country_filter text default null,
  p_max_distance_km int default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_lim int;
  v_me_lat double precision;
  v_me_lng double precision;
  v_country text;
  v_max_distance int;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  v_lim := coalesce(nullif(p_limit, 0), 20);
  if v_lim < 1 then
    v_lim := 20;
  end if;
  if v_lim > 100 then
    v_lim := 100;
  end if;

  select p.lat, p.lng into v_me_lat, v_me_lng
  from public.profiles p
  where p.id = v_uid;

  v_country := nullif(trim(coalesce(p_country_filter, '')), '');
  v_max_distance := p_max_distance_km;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'user_id', sub.id,
          'display_name', coalesce(sub.name, 'Member'),
          'bio', coalesce(sub.bio, ''),
          'age', sub.age,
          'gender', sub.gender,
          'avatar_url', sub.avatar_url,
          'gallery_urls', coalesce(sub.gallery_urls, '{}')
        )
      )
      from (
        select p.id, p.name, p.bio, p.age, p.gender, p.avatar_url, p.gallery_urls
        from public.profiles p
        inner join auth.users u on u.id = p.id
        where p.id <> v_uid
          and not exists (
            select 1
            from public.profile_interactions pi
            where pi.viewer_id = v_uid
              and pi.target_id = p.id
              and pi.swipe is not null
          )
          and (
            p_gender_filter is null
            or length(trim(p_gender_filter)) = 0
            or lower(trim(p_gender_filter)) = 'all'
            or (
              lower(trim(p_gender_filter)) = 'female'
              and lower(trim(coalesce(p.gender, ''))) in ('female', 'f', 'kadın', 'kadin')
            )
            or (
              lower(trim(p_gender_filter)) = 'male'
              and lower(trim(coalesce(p.gender, ''))) in ('male', 'm', 'erkek')
            )
            or (
              lower(trim(p_gender_filter)) = 'other'
              and not (lower(trim(coalesce(p.gender, ''))) in ('female', 'f', 'kadın', 'kadin'))
              and not (lower(trim(coalesce(p.gender, ''))) in ('male', 'm', 'erkek'))
            )
          )
          and (p_min_age is null or (p.age is not null and p.age >= p_min_age))
          and (p_max_age is null or (p.age is not null and p.age <= p_max_age))
          and (
            v_country is null
            or lower(trim(coalesce(p.country, ''))) = lower(v_country)
          )
          and (
            v_max_distance is null
            or v_me_lat is null
            or v_me_lng is null
            or (
              p.lat is not null
              and p.lng is not null
              and (
                6371 * 2 * asin(
                  sqrt(
                    pow(sin(radians((p.lat - v_me_lat) / 2)), 2) +
                    cos(radians(v_me_lat)) * cos(radians(p.lat)) *
                    pow(sin(radians((p.lng - v_me_lng) / 2)), 2)
                  )
                )
              ) <= v_max_distance
            )
          )
        order by random()
        limit v_lim
      ) sub
    ),
    '[]'::jsonb
  );
end;
$$;

comment on function public.get_discovery_profiles(int, text, int, int, text, int) is
  'Random discovery profiles with optional gender/age/country/distance filters, excluding already-swiped.';

grant execute on function public.get_discovery_profiles(int, text, int, int, text, int) to authenticated;
