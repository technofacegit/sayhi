-- Unread incoming likes count since a timestamp.

create or replace function public.get_who_liked_me_unread_count(
  p_seen_at timestamptz default null
)
returns integer
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  return coalesce(
    (
      select count(*)::integer
      from public.profile_interactions pi
      where pi.target_id = v_uid
        and pi.swipe = 'like'
        and (p_seen_at is null or pi.updated_at > p_seen_at)
    ),
    0
  );
end;
$$;

comment on function public.get_who_liked_me_unread_count(timestamptz) is
  'Unread incoming likes count since seen timestamp.';

grant execute on function public.get_who_liked_me_unread_count(timestamptz) to authenticated;
