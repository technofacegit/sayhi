-- 1:1 chat messages between mutually matched users (chat_id in the app = other user's id).

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users (id) on delete cascade,
  recipient_id uuid not null references auth.users (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  constraint chat_messages_not_self check (sender_id <> recipient_id),
  constraint chat_messages_body_len check (
    char_length(trim(body)) > 0
    and char_length(body) <= 4000
  )
);

create index if not exists chat_messages_sender_recipient_time
  on public.chat_messages (sender_id, recipient_id, created_at desc);

create index if not exists chat_messages_recipient_sender_time
  on public.chat_messages (recipient_id, sender_id, created_at desc);

alter table public.chat_messages enable row level security;

revoke all on public.chat_messages from public;
revoke all on public.chat_messages from anon;
revoke all on public.chat_messages from authenticated;
grant select, insert, update, delete on public.chat_messages to postgres;

-- Mutual match: both users liked each other (same as chat thread eligibility).
create or replace function public.is_mutual_match(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profile_interactions pi_me
    inner join public.profile_interactions pi_other
      on pi_other.viewer_id = pi_me.target_id
     and pi_other.target_id = pi_me.viewer_id
     and pi_other.swipe = 'like'
    where pi_me.viewer_id = a
      and pi_me.target_id = b
      and pi_me.swipe = 'like'
  );
$$;

comment on function public.is_mutual_match(uuid, uuid) is
  'True if both users have swipe=like toward each other.';

-- Partner header for chat UI (must be a mutual match).
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
    'gallery_urls', coalesce(to_jsonb(p.gallery_urls), '[]'::jsonb)
  )
  into v_row
  from public.profiles p
  inner join auth.users u on u.id = p.id
  where p.id = p_other_user_id;

  if v_row is null then
    raise exception 'PROFILE_NOT_FOUND'
      using errcode = 'P0001';
  end if;

  return v_row;
end;
$$;

comment on function public.get_chat_partner_preview(uuid) is
  'Display name/avatar/bio for the other user in a mutual match chat.';

grant execute on function public.get_chat_partner_preview(uuid) to authenticated;

-- List messages (oldest first for the UI).
create or replace function public.get_chat_messages(
  p_other_user_id uuid,
  p_limit int default 200
)
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

  if p_other_user_id = v_uid then
    raise exception 'INVALID_TARGET'
      using errcode = 'P0001';
  end if;

  if not public.is_mutual_match(v_uid, p_other_user_id) then
    raise exception 'NOT_A_MATCH'
      using errcode = 'P0001';
  end if;

  v_lim := coalesce(nullif(p_limit, 0), 200);
  if v_lim < 1 then
    v_lim := 200;
  end if;
  if v_lim > 500 then
    v_lim := 500;
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', x.id,
          'sender_id', x.sender_id,
          'body', x.body,
          'created_at', x.created_at
        )
        order by x.created_at asc
      )
      from (
        select *
        from public.chat_messages
        where (sender_id = v_uid and recipient_id = p_other_user_id)
           or (sender_id = p_other_user_id and recipient_id = v_uid)
        order by created_at desc
        limit v_lim
      ) x
    ),
    '[]'::jsonb
  );
end;
$$;

comment on function public.get_chat_messages(uuid, int) is
  'Messages between current user and another mutually matched user (newest slice, returned oldest-first).';

grant execute on function public.get_chat_messages(uuid, int) to authenticated;

-- Send a message.
create or replace function public.send_chat_message(
  p_recipient_id uuid,
  p_body text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_body text;
  v_id uuid;
  v_at timestamptz;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  if p_recipient_id = v_uid then
    raise exception 'INVALID_TARGET'
      using errcode = 'P0001';
  end if;

  v_body := trim(p_body);
  if length(v_body) = 0 or length(v_body) > 4000 then
    raise exception 'INVALID_BODY'
      using errcode = 'P0001';
  end if;

  if not public.is_mutual_match(v_uid, p_recipient_id) then
    raise exception 'NOT_A_MATCH'
      using errcode = 'P0001';
  end if;

  insert into public.chat_messages (sender_id, recipient_id, body)
  values (v_uid, p_recipient_id, v_body)
  returning id, created_at into v_id, v_at;

  return jsonb_build_object(
    'id', v_id,
    'sender_id', v_uid,
    'body', v_body,
    'created_at', v_at
  );
end;
$$;

comment on function public.send_chat_message(uuid, text) is
  'Insert a chat message to a mutually matched user.';

grant execute on function public.send_chat_message(uuid, text) to authenticated;

-- Thread list: include last message text/time from chat_messages.
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
          'unread_count', 0
        )
        order by sub.sort_at desc
      )
      from (
        select
          p_target.id as target_id,
          coalesce(p_target.name, 'Member') as display_name,
          p_target.avatar_url,
          greatest(pi_me.updated_at, pi_other.updated_at) as match_updated_at,
          lm.body as last_msg_body,
          lm.created_at as last_msg_at,
          coalesce(lm.created_at, greatest(pi_me.updated_at, pi_other.updated_at)) as sort_at
        from public.profile_interactions pi_me
        inner join public.profile_interactions pi_other
          on pi_other.viewer_id = pi_me.target_id
         and pi_other.target_id = pi_me.viewer_id
         and pi_other.swipe = 'like'
        inner join public.profiles p_target
          on p_target.id = pi_me.target_id
        inner join auth.users u_target
          on u_target.id = p_target.id
        left join lateral (
          select m.body, m.created_at
          from public.chat_messages m
          where (m.sender_id = v_uid and m.recipient_id = p_target.id)
             or (m.sender_id = p_target.id and m.recipient_id = v_uid)
          order by m.created_at desc
          limit 1
        ) lm on true
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

comment on function public.get_chat_threads(int) is
  'Mutual-like chat thread list with last message preview when messages exist.';
