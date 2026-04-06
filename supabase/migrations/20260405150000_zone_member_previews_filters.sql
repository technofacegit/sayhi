-- Add optional gender + age filters to paginated lobby RPC.

drop function if exists public.get_zone_member_previews_for_zone_page(uuid, int, int);

create or replace function public.get_zone_member_previews_for_zone_page(
  input_zone_id uuid,
  p_limit int,
  p_offset int,
  p_gender_filter text default null,
  p_min_age int default null,
  p_max_age int default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_count integer;
  v_lim int;
  v_off int;
  v_fetch int;
  v_has_more boolean;
  v_members jsonb;
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

  v_off := coalesce(p_offset, 0);
  if v_off < 0 then
    v_off := 0;
  end if;

  if not exists (
    select 1
    from public.zone_members zm
    where zm.zone_id = input_zone_id
      and zm.user_id = v_uid
      and zm.is_active = true
      and zm.updated_at >= now() - interval '24 hours'
  ) then
    raise exception 'NOT_IN_ZONE'
      using errcode = 'P0001';
  end if;

  select count(*)::integer
  into v_count
  from public.zone_members zm
  where zm.zone_id = input_zone_id
    and zm.is_active = true
    and zm.updated_at >= now() - interval '24 hours';

  v_fetch := v_lim + 1;

  with raw as (
    select
      zm.updated_at,
      p.id as profile_id,
      p.name,
      p.age,
      p.bio,
      p.avatar_url,
      p.gender
    from public.zone_members zm
    inner join public.profiles p on p.id = zm.user_id
    where zm.zone_id = input_zone_id
      and zm.is_active = true
      and zm.updated_at >= now() - interval '24 hours'
      and zm.user_id <> v_uid
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
    order by zm.updated_at desc
    limit v_fetch offset v_off
  )
  select
    (select count(*)::integer from raw) > v_lim,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'user_id', r.profile_id,
            'display_name', coalesce(r.name, 'Member'),
            'age', r.age,
            'bio', r.bio,
            'avatar_url', r.avatar_url,
            'gender', r.gender
          )
          order by r.updated_at desc
        )
        from (select * from raw limit v_lim) r
      ),
      '[]'::jsonb
    )
  into v_has_more, v_members;

  return jsonb_build_object(
    'active_count', coalesce(v_count, 0),
    'members', coalesce(v_members, '[]'::jsonb),
    'has_more', coalesce(v_has_more, false)
  );
end;
$$;

comment on function public.get_zone_member_previews_for_zone_page(uuid, int, int, text, int, int) is
  'Paginated lobby member previews with optional gender and age filters.';

grant execute on function public.get_zone_member_previews_for_zone_page(uuid, int, int, text, int, int) to authenticated;

-- Backward-compatible 3-arg overload (forwards with no filters).
create or replace function public.get_zone_member_previews_for_zone_page(
  input_zone_id uuid,
  p_limit int,
  p_offset int
)
returns jsonb
language sql
security definer
set search_path = public, auth
as $$
  select public.get_zone_member_previews_for_zone_page(
    input_zone_id,
    p_limit,
    p_offset,
    null::text,
    null::int,
    null::int
  );
$$;

comment on function public.get_zone_member_previews_for_zone_page(uuid, int, int) is
  'Paginated lobby previews without filters; calls the 6-parameter overload.';

grant execute on function public.get_zone_member_previews_for_zone_page(uuid, int, int) to authenticated;
