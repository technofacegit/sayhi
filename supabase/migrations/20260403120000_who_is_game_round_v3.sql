-- =============================================================================
-- OPTIONAL — REFERENCE / GREENFIELD ONLY
-- Production often uses: synthetic_profiles, who_is_questions, who_is_game_history
-- and get_who_is_game_round_v3 defined outside this repo. Do not apply if yours
-- already exists.
--
-- App uses get_who_is_game_round_v5 in production; this file is legacy v3 (optional).
-- Client parsing is flexible; typical payload includes question text, correct_index
-- (0..2), three profile rows, optional history_id — see lib/.../who_is_round_parser.dart
-- =============================================================================
--
-- Synthetic profiles pool + RPC for "Who is" game (one question, three options).

create table if not exists public.who_is_synthetic_profiles (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  avatar_url text,
  bio text not null
);

alter table public.who_is_synthetic_profiles enable row level security;

-- No policies: table is only read inside SECURITY DEFINER RPC.

comment on table public.who_is_synthetic_profiles is
  'Demo profiles for Who Is game rounds; not real users.';

insert into public.who_is_synthetic_profiles (display_name, avatar_url, bio)
select * from (values
  ('Maya', null::text, 'Product designer who sketches at cafés and collects vinyl from the 70s.'),
  ('Jordan', null, 'Night-shift nurse, daylight runner, always down for bad puns and good soup.'),
  ('Sam', null, 'Teaches guitar on weekends; believes the best dates start with a walk in the rain.'),
  ('Riley', null, 'Food truck regular, amateur photographer, allergic to small talk without snacks.'),
  ('Casey', null, 'Engineer by day, dungeon master by night; looking for curiosity and kind eyes.'),
  ('Quinn', null, 'Yoga at sunrise, salsa after sunset, forever chasing golden hour light.'),
  ('Noah', null, 'Rescues plants and playlists; happiest when plans are half spontaneous.'),
  ('Elif', null, 'Istanbul native, third-culture kid, writes poetry in two languages.')
) as v(display_name, avatar_url, bio)
where not exists (select 1 from public.who_is_synthetic_profiles limit 1);

drop function if exists public.get_who_is_game_round_v3(uuid);

create or replace function public.get_who_is_game_round_v3(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
begin
  v_uid := auth.uid();
  if v_uid is null or v_uid <> p_user_id then
    raise exception 'Unauthorized'
      using errcode = 'P0001';
  end if;

  if (select count(*)::int from public.who_is_synthetic_profiles) < 3 then
    raise exception 'WHO_IS_POOL_TOO_SMALL'
      using errcode = 'P0001';
  end if;

  return (
    with sel as (
      select id, display_name, avatar_url, bio
      from public.who_is_synthetic_profiles
      order by random()
      limit 3
    ),
    numbered as (
      select *, row_number() over (order by id) - 1 as idx
      from sel
    ),
    pick as (
      select floor(random() * 3)::int as v
    )
    select jsonb_build_object(
      'round_id', gen_random_uuid(),
      'question', (
        select format('Who matches this? "%s"', left(n.bio, 140))
        from numbered n, pick p
        where n.idx = p.v
      ),
      'correct_index', (select v from pick),
      'profiles', (
        select jsonb_agg(
          jsonb_build_object(
            'id', id,
            'display_name', display_name,
            'avatar_url', avatar_url,
            'bio', bio
          )
          order by idx
        )
        from numbered
      )
    )
  );
end;
$$;

comment on function public.get_who_is_game_round_v3(uuid) is
  'Returns one Who Is round: question text (from correct profile bio), 0-based correct_index, 3 synthetic profiles.';

grant execute on function public.get_who_is_game_round_v3(uuid) to authenticated;
