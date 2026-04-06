-- DEV / STAGING ONLY — DANGEROUS
-- ---------------------------------------------------------------------------
-- Removes ALL rows in auth.users (and cascades to identities/sessions where
-- configured), clears public user-linked rows, then recreates the 100 deterministic
-- seed accounts from 20260405120000_seed_100_profiles_with_photos + zone links +
-- gallery_urls backfill.
--
-- WARNING: This deletes EVERY Auth user in the project, including your own test
-- account. Re-register in the app or create a user manually after running.
-- Do NOT run against production with real customers.
-- ---------------------------------------------------------------------------

-- Public tables referencing auth.users (safe to clear before auth delete)
delete from public.profile_interactions;
delete from public.zone_members;
delete from public.story_views;
delete from public.icebreaker_answers;

-- Orphan profiles (no auth row) — harmless if empty
delete from public.profiles p
where not exists (select 1 from auth.users u where u.id = p.id);

-- All auth users — cascades to public.profiles when FK is profiles.id -> auth.users
delete from auth.users;

-- Any profiles left without users (should be none if FK cascaded)
delete from public.profiles;

-- ---------------------------------------------------------------------------
-- Re-seed: same logic as 20260405120000_seed_100_profiles_with_photos.sql
-- ---------------------------------------------------------------------------
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

do $$
declare
  inst uuid;
  pw text;
  ns uuid := 'c0000000-0000-5000-8000-000000000001'::uuid;
  uid uuid;
  em text;
  g text;
  av text;
  display_name text;
  bio text;
  age int;
  i int;
  female_names text[] := array[
    'Ayşe', 'Elif', 'Zeynep', 'Selin', 'Defne', 'Ece', 'Ceren', 'Burcu', 'Derya', 'Gizem',
    'İrem', 'Melis', 'Naz', 'Pınar', 'Sude', 'Tuğçe', 'Yasemin', 'Aslı', 'Büşra', 'Deniz'
  ];
  male_names text[] := array[
    'Mehmet', 'Can', 'Emre', 'Kerem', 'Burak', 'Onur', 'Arda', 'Barış', 'Cem', 'Efe',
    'Furkan', 'Gökhan', 'Hakan', 'İlker', 'Kaan', 'Levent', 'Murat', 'Oğuz', 'Tolga', 'Yusuf'
  ];
  bios text[] := array[
    'Kahve ve müzik; hafta sonu şehir dışına kaçmayı severim.',
    'Yüzme ve podcast; düşük tempo buluşmalar.',
    'Fotoğraf ve sergi; iyi sohbet > uzun mesaj.',
    'Koşu ve kahvaltı; planları yarı spontan bırakırım.',
    'Tasarım ve vinyl; tanışmak için mesaj at.',
    'Doğa yürüyüşü, sıcak çikolata, samimi sohbet.',
    'Salsa ve kahve; pozitif enerji arıyorum.',
    'Kitap ve sinema; küçük mekanları keşfetmek.',
    'Yoga sabah, caz akşam; dürüstlük önemli.',
    'Startup ve bisiklet; net iletişim severim.'
  ];
begin
  select id into inst from auth.instances limit 1;
  if inst is null then
    inst := '00000000-0000-0000-0000-000000000000';
  end if;

  pw := crypt('Seed100Profiles!NotProd', gen_salt('bf'));

  for i in 1..100 loop
    uid := uuid_generate_v5(ns, 'sayhi-profile-bulk-v1-' || i::text);
    em := 'seed.profile.' || i || '@sayhi.seed';

    if i <= 60 then
      g := 'female';
      av := format(
        'https://randomuser.me/api/portraits/women/%s.jpg',
        ((i - 1) % 99)::int
      );
      display_name := female_names[((i - 1) % 20) + 1] || ' ' || (50 + (i % 50))::text;
    else
      g := 'male';
      av := format(
        'https://randomuser.me/api/portraits/men/%s.jpg',
        ((i - 61) % 99)::int
      );
      display_name := male_names[((i - 61) % 20) + 1] || ' ' || (20 + (i % 40))::text;
    end if;

    age := 22 + ((i * 7) % 16);
    bio := bios[(i - 1) % 10 + 1];

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
      uid,
      inst,
      'authenticated',
      'authenticated',
      em,
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
      uid,
      jsonb_build_object('sub', uid::text, 'email', em),
      'email',
      em,
      now(),
      now(),
      now()
    );

    insert into public.profiles (id, name, bio, avatar_url, age, gender, email)
    values (uid, display_name, bio, av, age, g, em)
    on conflict (id) do update set
      name = excluded.name,
      bio = excluded.bio,
      avatar_url = excluded.avatar_url,
      age = excluded.age,
      gender = excluded.gender,
      email = excluded.email;
  end loop;
end $$;

-- Zone links: same as 20260405130000_seed_100_profiles_all_zones.sql
insert into public.zone_members (zone_id, user_id, is_active, joined_at, updated_at)
select
  z.id,
  u.uid,
  true,
  now(),
  now()
from public.zones z
cross join (
  select uuid_generate_v5(
    'c0000000-0000-5000-8000-000000000001'::uuid,
    'sayhi-profile-bulk-v1-' || gs::text
  ) as uid
  from generate_series(1, 100) gs
) u
on conflict (zone_id, user_id) do update set
  is_active = true,
  updated_at = now();

-- Gallery placeholders: same as 20260407120000_profiles_gallery_seed_urls.sql
update public.profiles p
set gallery_urls = (
  select coalesce(array_agg(u order by n), '{}')
  from (
    select
      n,
      'https://picsum.photos/seed/g'
        || substr(md5(p.id::text || '_' || n::text), 1, 16)
        || '/480/640' as u
    from generate_series(
      1,
      3 + mod(abs(hashtext(p.id::text)), 3)
    ) as n
  ) s
)
where coalesce(array_length(p.gallery_urls, 1), 0) = 0;
