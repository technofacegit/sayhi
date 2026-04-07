-- Optional test mode: auto-create reciprocal like to force a match for chat testing.
-- Keep this OFF in production by sending p_enable_test_auto_match=false.

drop function if exists public.save_profile_swipe(uuid, text);

create or replace function public.save_profile_swipe(
  p_target_id uuid,
  p_swipe text,
  p_enable_test_auto_match boolean default false
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_fav boolean;
  v_rev_fav boolean;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  if p_target_id = v_uid then
    raise exception 'Invalid target'
      using errcode = 'P0001';
  end if;

  if p_swipe is null or p_swipe not in ('like', 'dislike') then
    raise exception 'Invalid swipe'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from public.profiles p
    inner join auth.users u on u.id = p.id
    where p.id = p_target_id
  ) then
    raise exception 'Target is not a valid profile user'
      using errcode = 'P0001';
  end if;

  select coalesce(pi.is_favorite, false)
  into v_fav
  from public.profile_interactions pi
  where pi.viewer_id = v_uid
    and pi.target_id = p_target_id;

  if not found then
    v_fav := false;
  end if;

  insert into public.profile_interactions (
    viewer_id,
    target_id,
    swipe,
    is_favorite,
    updated_at
  )
  values (v_uid, p_target_id, p_swipe, v_fav, now())
  on conflict (viewer_id, target_id) do update
  set
    swipe = excluded.swipe,
    is_favorite = excluded.is_favorite,
    updated_at = excluded.updated_at;

  -- Test-only helper: make target like back immediately so chat list can be tested.
  if p_enable_test_auto_match and p_swipe = 'like' then
    select coalesce(pi.is_favorite, false)
    into v_rev_fav
    from public.profile_interactions pi
    where pi.viewer_id = p_target_id
      and pi.target_id = v_uid;

    if not found then
      v_rev_fav := false;
    end if;

    insert into public.profile_interactions (
      viewer_id,
      target_id,
      swipe,
      is_favorite,
      updated_at
    )
    values (p_target_id, v_uid, 'like', v_rev_fav, now())
    on conflict (viewer_id, target_id) do update
    set
      swipe = excluded.swipe,
      is_favorite = excluded.is_favorite,
      updated_at = excluded.updated_at;
  end if;
end;
$$;

comment on function public.save_profile_swipe(uuid, text, boolean) is
  'Like/dislike; optional test auto-match when enabled (reciprocal like).';

grant execute on function public.save_profile_swipe(uuid, text, boolean) to authenticated;

-- Backward-compatible 2-arg overload (production-safe default).
create or replace function public.save_profile_swipe(
  p_target_id uuid,
  p_swipe text
)
returns void
language sql
security definer
set search_path = public, auth
as $$
  select public.save_profile_swipe(
    p_target_id,
    p_swipe,
    false
  );
$$;

comment on function public.save_profile_swipe(uuid, text) is
  'Like/dislike wrapper with auto-match disabled.';

grant execute on function public.save_profile_swipe(uuid, text) to authenticated;
