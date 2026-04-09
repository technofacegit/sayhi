-- Profile self-management fields.

alter table public.profiles
  add column if not exists interests text[] default '{}'::text[],
  add column if not exists prompt_perfect_date text;

comment on column public.profiles.interests is
  'Optional interest tags selected by the user.';

comment on column public.profiles.prompt_perfect_date is
  'Optional prompt answer: what is your perfect date?';
