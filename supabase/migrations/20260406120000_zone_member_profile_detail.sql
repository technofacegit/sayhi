-- Extra profile photos + viewer interactions (like / dislike / favorite) for zone lobby profile detail.

alter table public.profiles
  add column if not exists gallery_urls text[] not null default '{}';

comment on column public.profiles.gallery_urls is
  'Additional public photo URLs (avatar_url remains the primary).';

create table if not exists public.profile_interactions (
  viewer_id uuid not null references auth.users (id) on delete cascade,
  target_id uuid not null references auth.users (id) on delete cascade,
  swipe text,
  is_favorite boolean not null default false,
  updated_at timestamptz not null default now(),
  constraint profile_interactions_pkey primary key (viewer_id, target_id),
  constraint profile_interactions_not_self check (viewer_id <> target_id),
  constraint profile_interactions_swipe_check check (
    swipe is null or swipe in ('like', 'dislike')
  )
);

create index if not exists profile_interactions_target_idx
  on public.profile_interactions (target_id);

comment on table public.profile_interactions is
  'Current user swipe/favorite toward another profile (zone flows).';

alter table public.profile_interactions enable row level security;

drop policy if exists "profile_interactions_select_own" on public.profile_interactions;
create policy "profile_interactions_select_own"
  on public.profile_interactions for select
  using (viewer_id = auth.uid());

drop policy if exists "profile_interactions_insert_own" on public.profile_interactions;
create policy "profile_interactions_insert_own"
  on public.profile_interactions for insert
  with check (
    viewer_id = auth.uid()
    and viewer_id <> target_id
  );

drop policy if exists "profile_interactions_update_own" on public.profile_interactions;
create policy "profile_interactions_update_own"
  on public.profile_interactions for update
  using (viewer_id = auth.uid())
  with check (
    viewer_id = auth.uid()
    and viewer_id <> target_id
  );

drop policy if exists "profile_interactions_delete_own" on public.profile_interactions;
create policy "profile_interactions_delete_own"
  on public.profile_interactions for delete
  using (viewer_id = auth.uid());

create or replace function public.get_zone_member_profile_detail(
  p_zone_id uuid,
  p_target_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_profile jsonb;
  v_interaction jsonb;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  if p_target_user_id = v_uid then
    raise exception 'INVALID_TARGET'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from public.zone_members zm
    where zm.zone_id = p_zone_id
      and zm.user_id = v_uid
      and zm.is_active = true
      and zm.updated_at >= now() - interval '24 hours'
  ) then
    raise exception 'NOT_IN_ZONE'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from public.zone_members zm
    where zm.zone_id = p_zone_id
      and zm.user_id = p_target_user_id
      and zm.is_active = true
      and zm.updated_at >= now() - interval '24 hours'
  ) then
    raise exception 'TARGET_NOT_IN_ZONE'
      using errcode = 'P0001';
  end if;

  select jsonb_build_object(
    'user_id', p.id,
    'display_name', coalesce(p.name, ''),
    'bio', coalesce(p.bio, ''),
    'age', p.age,
    'gender', p.gender,
    'avatar_url', p.avatar_url,
    'gallery_urls', coalesce(p.gallery_urls, '{}')
  )
  into v_profile
  from public.profiles p
  where p.id = p_target_user_id;

  if v_profile is null then
    raise exception 'PROFILE_NOT_FOUND'
      using errcode = 'P0001';
  end if;

  select jsonb_build_object(
    'swipe', pi.swipe,
    'is_favorite', coalesce(pi.is_favorite, false)
  )
  into v_interaction
  from public.profile_interactions pi
  where pi.viewer_id = v_uid
    and pi.target_id = p_target_user_id;

  return jsonb_build_object(
    'profile', v_profile,
    'interaction', v_interaction
  );
end;
$$;

comment on function public.get_zone_member_profile_detail(uuid, uuid) is
  'Full profile + viewer interaction for a user in the same active zone (24h).';

grant execute on function public.get_zone_member_profile_detail(uuid, uuid) to authenticated;
