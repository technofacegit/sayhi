-- Dynamic country options for discovery filters.

create table if not exists public.discovery_countries (
  code text primary key,
  name text not null,
  sort_order int not null default 0,
  is_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.discovery_countries (code, name, sort_order, is_enabled)
values
  ('TR', 'Turkey', 10, true),
  ('US', 'United States', 20, true),
  ('GB', 'United Kingdom', 30, true),
  ('DE', 'Germany', 40, true),
  ('FR', 'France', 50, true),
  ('ES', 'Spain', 60, true),
  ('IT', 'Italy', 70, true),
  ('NL', 'Netherlands', 80, true),
  ('CA', 'Canada', 90, true),
  ('AU', 'Australia', 100, true)
on conflict (code) do update
set
  name = excluded.name,
  sort_order = excluded.sort_order,
  is_enabled = excluded.is_enabled;

alter table public.discovery_countries enable row level security;

drop policy if exists "discovery_countries_read_all" on public.discovery_countries;
create policy "discovery_countries_read_all"
  on public.discovery_countries
  for select
  using (true);

create or replace function public.get_discovery_countries()
returns jsonb
language sql
security definer
set search_path = public, auth
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'code', c.code,
        'name', c.name
      )
      order by c.sort_order asc, c.name asc
    ),
    '[]'::jsonb
  )
  from public.discovery_countries c
  where c.is_enabled = true;
$$;

grant execute on function public.get_discovery_countries() to authenticated;
