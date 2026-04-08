-- Chat presence + read receipts for list/profile metadata.

alter table public.chat_messages
  add column if not exists read_at timestamptz;

create index if not exists chat_messages_recipient_unread_idx
  on public.chat_messages (recipient_id, sender_id, read_at)
  where read_at is null;

create table if not exists public.user_presence (
  user_id uuid primary key references auth.users (id) on delete cascade,
  last_online_at timestamptz not null default now()
);

alter table public.user_presence enable row level security;

revoke all on public.user_presence from public;
revoke all on public.user_presence from anon;
revoke all on public.user_presence from authenticated;
grant select, insert, update, delete on public.user_presence to postgres;

drop policy if exists "user_presence_select_all" on public.user_presence;
create policy "user_presence_select_all"
  on public.user_presence
  for select
  using (true);

drop policy if exists "user_presence_upsert_own" on public.user_presence;
create policy "user_presence_upsert_own"
  on public.user_presence
  for insert
  with check (user_id = auth.uid());

drop policy if exists "user_presence_update_own" on public.user_presence;
create policy "user_presence_update_own"
  on public.user_presence
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create or replace function public.touch_my_presence()
returns timestamptz
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_now timestamptz;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;
  v_now := now();

  insert into public.user_presence (user_id, last_online_at)
  values (v_uid, v_now)
  on conflict (user_id) do update
    set last_online_at = excluded.last_online_at;

  return v_now;
end;
$$;

grant execute on function public.touch_my_presence() to authenticated;

create or replace function public.mark_chat_read(p_other_user_id uuid)
returns int
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_count int;
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

  update public.chat_messages
     set read_at = now()
   where sender_id = p_other_user_id
     and recipient_id = v_uid
     and read_at is null;

  get diagnostics v_count = row_count;
  return coalesce(v_count, 0);
end;
$$;

grant execute on function public.mark_chat_read(uuid) to authenticated;

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

create or replace function public.get_chat_threads(p_limit int default 50)
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

  v_lim := coalesce(nullif(p_limit, 0), 50);
  if v_lim < 1 then
    v_lim := 50;
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
          'last_message', coalesce(sub.last_msg_body, ''),
          'last_message_at', sub.sort_at,
          'unread_count', sub.unread_count,
          'last_online_at', sub.last_online_at,
          'last_message_is_mine', sub.last_message_is_mine,
          'last_message_read_at', sub.last_message_read_at
        )
        order by sub.sort_at desc
      )
      from (
        select
          p_target.id as target_id,
          coalesce(p_target.name, 'Member') as display_name,
          p_target.avatar_url,
          up.last_online_at,
          lm.body as last_msg_body,
          lm.created_at as last_msg_at,
          lm.sender_id = v_uid as last_message_is_mine,
          lm.read_at as last_message_read_at,
          coalesce(lm.created_at, greatest(pi_me.updated_at, pi_other.updated_at)) as sort_at,
          coalesce(um.unread_count, 0) as unread_count
        from public.profile_interactions pi_me
        inner join public.profile_interactions pi_other
          on pi_other.viewer_id = pi_me.target_id
         and pi_other.target_id = pi_me.viewer_id
         and pi_other.swipe = 'like'
        inner join public.profiles p_target
          on p_target.id = pi_me.target_id
        inner join auth.users u_target
          on u_target.id = p_target.id
        left join public.user_presence up
          on up.user_id = p_target.id
        left join lateral (
          select m.body, m.created_at, m.sender_id, m.read_at
          from public.chat_messages m
          where (m.sender_id = v_uid and m.recipient_id = p_target.id)
             or (m.sender_id = p_target.id and m.recipient_id = v_uid)
          order by m.created_at desc
          limit 1
        ) lm on true
        left join lateral (
          select count(*)::int as unread_count
          from public.chat_messages um
          where um.sender_id = p_target.id
            and um.recipient_id = v_uid
            and um.read_at is null
        ) um on true
        where pi_me.viewer_id = v_uid
          and pi_me.swipe = 'like'
        order by coalesce(lm.created_at, greatest(pi_me.updated_at, pi_other.updated_at)) desc
        limit v_lim
      ) sub
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function public.get_chat_threads(int) to authenticated;
