-- Paginated "Say Hi" lobby: same shape as zone lobby page, no zone membership (profiles ⋈ auth.users).

create or replace function public.get_say_hi_member_previews_page(
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

  select count(*)::integer
  into v_count
  from public.profiles p
  inner join auth.users u on u.id = p.id
  where p.id <> v_uid
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
    and (p_max_age is null or (p.age is not null and p.age <= p_max_age));

  v_fetch := v_lim + 1;

  with raw as (
    select
      p.id as profile_id,
      p.name,
      p.age,
      p.bio,
      p.avatar_url,
      p.gender
    from public.profiles p
    inner join auth.users u on u.id = p.id
    where p.id <> v_uid
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
    order by p.id asc
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
          order by r.profile_id
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

comment on function public.get_say_hi_member_previews_page(int, int, text, int, int) is
  'Paginated member previews for Say Hi lobby (no zone); same JSON shape as zone lobby page.';

grant execute on function public.get_say_hi_member_previews_page(int, int, text, int, int) to authenticated;
