-- Delete a single message from a mutual chat.
-- Authenticated participants of the message can delete it.

create or replace function public.delete_chat_message(p_message_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_sender uuid;
  v_recipient uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  select m.sender_id, m.recipient_id
    into v_sender, v_recipient
  from public.chat_messages m
  where m.id = p_message_id;

  if v_sender is null then
    return false;
  end if;

  if v_uid <> v_sender and v_uid <> v_recipient then
    raise exception 'NOT_A_PARTICIPANT'
      using errcode = 'P0001';
  end if;

  if not public.is_mutual_match(v_sender, v_recipient) then
    raise exception 'NOT_A_MATCH'
      using errcode = 'P0001';
  end if;

  delete from public.chat_messages where id = p_message_id;
  return true;
end;
$$;

grant execute on function public.delete_chat_message(uuid) to authenticated;
