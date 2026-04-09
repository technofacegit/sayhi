-- Canonical language list for chat translation UI.

create table if not exists public.chat_translation_languages (
  code text primary key,
  label text not null,
  sort_order int not null default 0,
  is_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.chat_translation_languages (code, label, sort_order, is_enabled)
values
  ('tr', 'Turkish', 10, true),
  ('en', 'English', 20, true),
  ('es', 'Spanish', 30, true),
  ('de', 'German', 40, true),
  ('fr', 'French', 50, true),
  ('ar', 'Arabic', 60, true),
  ('ru', 'Russian', 70, true)
on conflict (code) do update
set
  label = excluded.label,
  sort_order = excluded.sort_order,
  is_enabled = excluded.is_enabled;

alter table public.chat_translation_languages enable row level security;

drop policy if exists "chat_translation_languages_read_all"
  on public.chat_translation_languages;
create policy "chat_translation_languages_read_all"
  on public.chat_translation_languages
  for select
  using (true);

create or replace function public.get_chat_translation_languages()
returns jsonb
language sql
security definer
set search_path = public, auth
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'code', l.code,
        'label', l.label
      )
      order by l.sort_order asc, l.code asc
    ),
    '[]'::jsonb
  )
  from public.chat_translation_languages l
  where l.is_enabled = true;
$$;

grant execute on function public.get_chat_translation_languages() to authenticated;
