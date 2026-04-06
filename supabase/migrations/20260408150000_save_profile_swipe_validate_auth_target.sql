-- Fail fast with a clear error if target is not a real auth user (FK profile_interactions_target_id_fkey).

create or replace function public.save_profile_swipe(p_target_id uuid, p_swipe text)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_fav boolean;
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

  if not exists (select 1 from auth.users au where au.id = p_target_id) then
    raise exception 'Target is not a registered user'
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
end;
$$;

comment on function public.save_profile_swipe(uuid, text) is
  'Like/dislike for current user; target must exist in auth.users; preserves is_favorite.';

grant execute on function public.save_profile_swipe(uuid, text) to authenticated;
