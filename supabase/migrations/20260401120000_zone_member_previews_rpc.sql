-- Zone grid: RPC joins [zone_members] (membership rows) + [profiles].
-- Does not create a view named zone_memberships: that name may already exist as a
-- table in your project; use [zone_members] here to match existing RLS and RPCs.

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
        'avatar_url', p.avatar_url
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

-- Client realtime subscriptions on [zone_members] (Flutter channel).
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'zone_members'
  ) then
    alter publication supabase_realtime add table public.zone_members;
  end if;
end $$;
