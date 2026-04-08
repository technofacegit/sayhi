-- Video-note support for chat messages (Telegram-like circular clips).

alter table public.chat_messages
  add column if not exists message_type text not null default 'text',
  add column if not exists media_url text,
  add column if not exists media_duration_sec int;

alter table public.chat_messages
  drop constraint if exists chat_messages_body_len;

alter table public.chat_messages
  add constraint chat_messages_message_type_check
  check (message_type in ('text', 'video_note'));

alter table public.chat_messages
  add constraint chat_messages_payload_check
  check (
    (
      message_type = 'text'
      and char_length(trim(body)) > 0
      and char_length(body) <= 4000
      and media_url is null
    )
    or
    (
      message_type = 'video_note'
      and media_url is not null
      and char_length(coalesce(body, '')) <= 4000
    )
  );

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'chat-media',
  'chat-media',
  true,
  31457280,
  array['video/mp4', 'video/quicktime']
)
on conflict (id) do nothing;

drop policy if exists "chat_media_read_all" on storage.objects;
create policy "chat_media_read_all"
on storage.objects for select
using (bucket_id = 'chat-media');

drop policy if exists "chat_media_insert_own_folder" on storage.objects;
create policy "chat_media_insert_own_folder"
on storage.objects for insert
with check (
  bucket_id = 'chat-media'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "chat_media_update_own_folder" on storage.objects;
create policy "chat_media_update_own_folder"
on storage.objects for update
using (
  bucket_id = 'chat-media'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'chat-media'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "chat_media_delete_own_folder" on storage.objects;
create policy "chat_media_delete_own_folder"
on storage.objects for delete
using (
  bucket_id = 'chat-media'
  and auth.uid()::text = (storage.foldername(name))[1]
);

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
          'message_type', x.message_type,
          'media_url', x.media_url,
          'media_duration_sec', x.media_duration_sec,
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

grant execute on function public.get_chat_messages(uuid, int) to authenticated;

create or replace function public.send_chat_video_note(
  p_recipient_id uuid,
  p_media_url text,
  p_media_duration_sec int default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_id uuid;
  v_at timestamptz;
  v_url text;
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

  v_url := trim(coalesce(p_media_url, ''));
  if char_length(v_url) = 0 then
    raise exception 'INVALID_MEDIA_URL'
      using errcode = 'P0001';
  end if;

  if not public.is_mutual_match(v_uid, p_recipient_id) then
    raise exception 'NOT_A_MATCH'
      using errcode = 'P0001';
  end if;

  insert into public.chat_messages (
    sender_id,
    recipient_id,
    body,
    message_type,
    media_url,
    media_duration_sec
  )
  values (
    v_uid,
    p_recipient_id,
    '',
    'video_note',
    v_url,
    case
      when p_media_duration_sec is null or p_media_duration_sec < 0 then null
      else p_media_duration_sec
    end
  )
  returning id, created_at into v_id, v_at;

  return jsonb_build_object(
    'id', v_id,
    'sender_id', v_uid,
    'body', '',
    'message_type', 'video_note',
    'media_url', v_url,
    'media_duration_sec', p_media_duration_sec,
    'created_at', v_at
  );
end;
$$;

grant execute on function public.send_chat_video_note(uuid, text, int) to authenticated;

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
          case
            when lm.message_type = 'video_note' then 'Video note'
            else lm.body
          end as last_msg_body,
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
          select m.body, m.created_at, m.sender_id, m.read_at, m.message_type
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
