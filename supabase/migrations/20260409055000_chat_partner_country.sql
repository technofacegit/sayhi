-- Include country in chat partner profile payload.

create or replace function public.get_chat_partner_preview(p_other_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_row jsonb;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  if p_other_user_id = v_uid then
    raise exception 'INVALID_TARGET'
      using errcode = 'P0001';
  end if;

  if not public.is_mutual_match(v_uid, p_other_user_id) then
    raise exception 'NOT_A_MATCH'
      using errcode = 'P0001';
  end if;

  select jsonb_build_object(
    'user_id', p.id,
    'name', coalesce(p.name, 'Member'),
    'avatar_url', coalesce(p.avatar_url, ''),
    'bio', coalesce(p.bio, ''),
    'country', p.country,
    'gallery_urls', coalesce(to_jsonb(p.gallery_urls), '[]'::jsonb),
    'last_online_at', up.last_online_at
  )
  into v_row
  from public.profiles p
  inner join auth.users u on u.id = p.id
  left join public.user_presence up on up.user_id = p.id
  where p.id = p_other_user_id;

  if v_row is null then
    raise exception 'PROFILE_NOT_FOUND'
      using errcode = 'P0001';
  end if;

  return v_row;
end;
$$;

grant execute on function public.get_chat_partner_preview(uuid) to authenticated;
