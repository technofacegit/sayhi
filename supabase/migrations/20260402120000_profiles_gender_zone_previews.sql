-- Optional profile gender for zone grid border colors (female / male / other).

alter table public.profiles
  add column if not exists gender text;

comment on column public.profiles.gender is
  'Optional: female, male, or other (lowercase recommended for clients).';

drop function if exists public.get_zone_member_previews_for_zone(uuid);

create or replace function public.get_zone_member_previews_for_zone(input_zone_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_count integer;
  v_members jsonb;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
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

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'user_id', p.id,
        'display_name', coalesce(p.name, 'Member'),
        'age', p.age,
        'bio', p.bio,
        'avatar_url', p.avatar_url,
        'gender', p.gender
      )
      order by zm.updated_at desc
    ),
    '[]'::jsonb
  )
  into v_members
  from public.zone_members zm
  inner join public.profiles p on p.id = zm.user_id
  where zm.zone_id = input_zone_id
    and zm.is_active = true
    and zm.updated_at >= now() - interval '24 hours'
    and zm.user_id <> v_uid;

  return jsonb_build_object(
    'active_count', coalesce(v_count, 0),
    'members', coalesce(v_members, '[]'::jsonb)
  );
end;
$$;

comment on function public.get_zone_member_previews_for_zone(uuid) is
  'Members in zone (profiles + zone_members) for callers who are active in that zone; excludes self.';

grant execute on function public.get_zone_member_previews_for_zone(uuid) to authenticated;
