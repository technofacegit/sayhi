-- Include country in discovery and zone profile-detail payloads.

drop function if exists public.get_discovery_profiles(int, text, int, int, text[], int);

create or replace function public.get_discovery_profiles(
  p_limit int default 20,
  p_gender_filter text default null,
  p_min_age int default null,
  p_max_age int default null,
  p_country_filters text[] default null,
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
  v_max_distance int;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  v_lim := coalesce(nullif(p_limit, 0), 20);
  if v_lim < 1 then v_lim := 20; end if;
  if v_lim > 100 then v_lim := 100; end if;

  select p.lat, p.lng into v_me_lat, v_me_lng
  from public.profiles p
  where p.id = v_uid;

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
          'country', sub.country,
          'avatar_url', sub.avatar_url,
          'gallery_urls', coalesce(sub.gallery_urls, '{}')
        )
      )
      from (
        select p.id, p.name, p.bio, p.age, p.gender, p.country, p.avatar_url, p.gallery_urls
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
            p_country_filters is null
            or cardinality(p_country_filters) = 0
            or exists (
              select 1
              from unnest(p_country_filters) x
              where lower(trim(coalesce(p.country, ''))) = lower(trim(x))
            )
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

grant execute on function public.get_discovery_profiles(int, text, int, int, text[], int) to authenticated;

create or replace function public.get_zone_member_profile_detail(
  p_zone_id uuid,
  p_target_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_profile jsonb;
  v_interaction jsonb;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  if p_target_user_id = v_uid then
    raise exception 'INVALID_TARGET'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from public.zone_members zm
    where zm.zone_id = p_zone_id
      and zm.user_id = v_uid
      and zm.is_active = true
      and zm.updated_at >= now() - interval '24 hours'
  ) then
    raise exception 'NOT_IN_ZONE'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from public.zone_members zm
    where zm.zone_id = p_zone_id
      and zm.user_id = p_target_user_id
      and zm.is_active = true
      and zm.updated_at >= now() - interval '24 hours'
  ) then
    raise exception 'TARGET_NOT_IN_ZONE'
      using errcode = 'P0001';
  end if;

  select jsonb_build_object(
    'user_id', p.id,
    'display_name', coalesce(p.name, ''),
    'bio', coalesce(p.bio, ''),
    'age', p.age,
    'gender', p.gender,
    'country', p.country,
    'avatar_url', p.avatar_url,
    'gallery_urls', coalesce(p.gallery_urls, '{}')
  )
  into v_profile
  from public.profiles p
  where p.id = p_target_user_id;

  if v_profile is null then
    raise exception 'PROFILE_NOT_FOUND'
      using errcode = 'P0001';
  end if;

  select jsonb_build_object(
    'swipe', pi.swipe,
    'is_favorite', coalesce(pi.is_favorite, false)
  )
  into v_interaction
  from public.profile_interactions pi
  where pi.viewer_id = v_uid
    and pi.target_id = p_target_user_id;

  return jsonb_build_object(
    'profile', v_profile,
    'interaction', v_interaction
  );
end;
$$;

grant execute on function public.get_zone_member_profile_detail(uuid, uuid) to authenticated;
