-- Paginated profiles the current user favorited (profile_interactions.is_favorite = true).

create or replace function public.get_favorited_profiles_page(
  p_limit int,
  p_offset int
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
  from public.profile_interactions pi
  inner join public.profiles p on p.id = pi.target_id
  inner join auth.users u on u.id = pi.target_id
  where pi.viewer_id = v_uid
    and pi.is_favorite = true;

  v_fetch := v_lim + 1;

  with raw as (
    select
      pi.updated_at as sort_at,
      p.id as profile_id,
      p.name,
      p.age,
      p.bio,
      p.avatar_url,
      p.gender
    from public.profile_interactions pi
    inner join public.profiles p on p.id = pi.target_id
    inner join auth.users u on u.id = pi.target_id
    where pi.viewer_id = v_uid
      and pi.is_favorite = true
    order by pi.updated_at desc
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
          order by r.sort_at desc
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

comment on function public.get_favorited_profiles_page(int, int) is
  'Paginated profiles the viewer marked as favorite (same member JSON as lobby page).';

grant execute on function public.get_favorited_profiles_page(int, int) to authenticated;
