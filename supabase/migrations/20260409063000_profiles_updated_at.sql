-- Client (MyProfileRepository) sets updated_at on profile updates; PostgREST PGRST204
-- if the column is missing from public.profiles.
alter table public.profiles
  add column if not exists updated_at timestamptz not null default now();

comment on column public.profiles.updated_at is
  'Last time this profile row was updated (app sets on save / photo changes).';
