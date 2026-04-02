-- Icebreaker mini-game: questions in DB + per-zone answers for analytics.

create table if not exists public.icebreaker_questions (
  id uuid primary key default gen_random_uuid(),
  prompt text not null,
  options jsonb not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint icebreaker_questions_options_array check (jsonb_typeof(options) = 'array')
);

create table if not exists public.icebreaker_answers (
  id uuid primary key default gen_random_uuid(),
  zone_id uuid not null references public.zones(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.icebreaker_questions(id) on delete cascade,
  option_index integer not null,
  created_at timestamptz not null default now(),
  unique (zone_id, user_id, question_id)
);

create index if not exists icebreaker_answers_zone_idx
  on public.icebreaker_answers(zone_id);

create index if not exists icebreaker_questions_sort_idx
  on public.icebreaker_questions(sort_order)
  where is_active = true;

alter table public.icebreaker_questions enable row level security;
alter table public.icebreaker_answers enable row level security;

drop policy if exists "icebreaker_questions_select_active" on public.icebreaker_questions;
create policy "icebreaker_questions_select_active"
on public.icebreaker_questions
for select
to authenticated
using (is_active = true);

drop policy if exists "icebreaker_answers_select_own" on public.icebreaker_answers;
create policy "icebreaker_answers_select_own"
on public.icebreaker_answers
for select
to authenticated
using (auth.uid() = user_id);

revoke insert, update, delete on public.icebreaker_answers from authenticated;

-- Submit answer only if caller is an active zone member (24h window) and option is valid.
create or replace function public.submit_icebreaker_answer(
  p_zone_id uuid,
  p_question_id uuid,
  p_option_index integer
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_len integer;
  v_uid uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
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

  select jsonb_array_length(q.options)
  into v_len
  from public.icebreaker_questions q
  where q.id = p_question_id
    and q.is_active = true;

  if v_len is null then
    raise exception 'INVALID_QUESTION'
      using errcode = 'P0001';
  end if;

  if p_option_index < 0 or p_option_index >= v_len then
    raise exception 'INVALID_OPTION'
      using errcode = 'P0001';
  end if;

  insert into public.icebreaker_answers (
    zone_id,
    user_id,
    question_id,
    option_index,
    created_at
  )
  values (
    p_zone_id,
    v_uid,
    p_question_id,
    p_option_index,
    now()
  )
  on conflict (zone_id, user_id, question_id)
  do update set
    option_index = excluded.option_index,
    created_at = excluded.created_at;
end;
$$;

grant execute on function public.submit_icebreaker_answer(uuid, uuid, integer) to authenticated;

comment on table public.icebreaker_questions is
  'Prompts for empty-zone icebreaker; options is a JSON array of 2–3 label strings.';
comment on function public.submit_icebreaker_answer(uuid, uuid, integer) is
  'Stores one pick; requires active zone membership (24h).';

-- Seed (first 3 by sort_order used as default mini-game). Idempotent.
do $$
begin
  if exists (select 1 from public.icebreaker_questions limit 1) then
    return;
  end if;
  insert into public.icebreaker_questions (prompt, options, sort_order, is_active)
  values
    (
      'Your ideal first drink here?',
      '["Coffee", "Something stronger", "Water — pacing myself"]'::jsonb,
      1,
      true
    ),
    (
      'Best icebreaker superpower?',
      '["Great listener", "Tells good jokes"]'::jsonb,
      2,
      true
    ),
    (
      'Tonight''s vibe?',
      '["Chill corner", "Center of the room", "Surprise me"]'::jsonb,
      3,
      true
    ),
    (
      'Pick a conversation starter:',
      '["Travel stories", "Music", "Food hot takes"]'::jsonb,
      4,
      true
    ),
    (
      'You notice someone interesting. You…',
      '["Smile first", "Wait for eye contact"]'::jsonb,
      5,
      true
    );
end $$;
