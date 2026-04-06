-- Lobby grid: seed 3 demo "other members" so [get_zone_member_previews_for_zone] is not empty.
-- Inserts auth.users + auth.identities + public.profiles + public.zone_members for every zone.
-- Idempotent (fixed user UUIDs, ON CONFLICT). Intended for dev/staging.
--
-- Requires: public.zones has at least one row. Run via `supabase db push` or SQL editor.

create extension if not exists pgcrypto;

do $$
declare
  inst uuid;
  pw text := crypt('LobbyDemo!NotForProd', gen_salt('bf'));
  r record;
begin
  select id into inst from auth.instances limit 1;
  if inst is null then
    inst := '00000000-0000-0000-0000-000000000000';
  end if;

  for r in
    select *
    from (
      values
        ('a0000001-0000-4000-8000-000000000001'::uuid, 'lobby.demo.1@sayhi.seed'),
        ('a0000002-0000-4000-8000-000000000002'::uuid, 'lobby.demo.2@sayhi.seed'),
        ('a0000003-0000-4000-8000-000000000003'::uuid, 'lobby.demo.3@sayhi.seed')
    ) as t (uid, em)
  loop
    if exists (select 1 from auth.users where id = r.uid) then
      continue;
    end if;

    insert into auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) values (
      r.uid,
      inst,
      'authenticated',
      'authenticated',
      r.em,
      pw,
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      now(),
      now()
    );

    insert into auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      last_sign_in_at,
      created_at,
      updated_at
    ) values (
      gen_random_uuid(),
      r.uid,
      jsonb_build_object('sub', r.uid::text, 'email', r.em),
      'email',
      r.em,
      now(),
      now(),
      now()
    );
  end loop;
end $$;

insert into public.profiles (id, name, bio, avatar_url, age, gender, email)
values
  (
    'a0000001-0000-4000-8000-000000000001',
    'Alex',
    'Weekend hiker, weekday designer. Always up for good coffee.',
    null,
    29,
    'male',
    'lobby.demo.1@sayhi.seed'
  ),
  (
    'a0000002-0000-4000-8000-000000000002',
    'Sam',
    'Teaches guitar; believes the best plans start with a walk.',
    null,
    26,
    'female',
    'lobby.demo.2@sayhi.seed'
  ),
  (
    'a0000003-0000-4000-8000-000000000003',
    'Jordan',
    'Night-shift nurse, daylight runner. Bad puns, good soup.',
    null,
    31,
    'male',
    'lobby.demo.3@sayhi.seed'
  )
on conflict (id) do update set
  name = excluded.name,
  bio = excluded.bio,
  avatar_url = excluded.avatar_url,
  age = excluded.age,
  gender = excluded.gender,
  email = excluded.email;

insert into public.zone_members (zone_id, user_id, is_active, joined_at, updated_at)
select
  z.id,
  u.user_id,
  true,
  now(),
  now()
from public.zones z
cross join (
  values
    ('a0000001-0000-4000-8000-000000000001'::uuid),
    ('a0000002-0000-4000-8000-000000000002'::uuid),
    ('a0000003-0000-4000-8000-000000000003'::uuid)
) as u (user_id)
on conflict (zone_id, user_id) do update set
  is_active = true,
  updated_at = now();
