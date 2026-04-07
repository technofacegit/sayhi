-- New matches strip for Chats tab (mutual likes, regardless of conversation).

create or replace function public.get_new_matches(p_limit int default 30)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_lim int;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  v_lim := coalesce(nullif(p_limit, 0), 30);
  if v_lim < 1 then
    v_lim := 30;
  end if;
  if v_lim > 200 then
    v_lim := 200;
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'chat_id', sub.target_id,
          'user_id', sub.target_id,
          'name', sub.display_name,
          'avatar_url', sub.avatar_url,
          'last_message', '',
          'last_message_at', sub.matched_at,
          'unread_count', 0
        )
        order by sub.matched_at desc
      )
      from (
        select
          p_target.id as target_id,
          coalesce(p_target.name, 'Member') as display_name,
          p_target.avatar_url,
          greatest(pi_me.updated_at, pi_other.updated_at) as matched_at
        from public.profile_interactions pi_me
        inner join public.profile_interactions pi_other
          on pi_other.viewer_id = pi_me.target_id
         and pi_other.target_id = pi_me.viewer_id
         and pi_other.swipe = 'like'
        inner join public.profiles p_target
          on p_target.id = pi_me.target_id
        inner join auth.users u_target
          on u_target.id = p_target.id
        where pi_me.viewer_id = v_uid
          and pi_me.swipe = 'like'
        order by greatest(pi_me.updated_at, pi_other.updated_at) desc
        limit v_lim
      ) sub
    ),
    '[]'::jsonb
  );
end;
$$;

comment on function public.get_new_matches(int) is
  'Recent mutual-like matches for chats top strip.';

grant execute on function public.get_new_matches(int) to authenticated;
