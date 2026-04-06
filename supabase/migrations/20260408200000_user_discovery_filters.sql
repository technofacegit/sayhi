-- Persist home discovery filters per user (survives app reinstall when user logs back in).

create table if not exists public.user_discovery_filters (
  user_id uuid not null primary key references auth.users (id) on delete cascade,
  gender text null,
  min_age integer null,
  max_age integer null,
  updated_at timestamptz not null default now(),
  constraint user_discovery_filters_gender_ck check (
    gender is null or gender in ('female', 'male', 'other')
  ),
  constraint user_discovery_filters_age_ck check (
    (min_age is null and max_age is null)
    or (
      min_age is not null
      and max_age is not null
      and min_age between 18 and 99
      and max_age between 18 and 99
      and min_age <= max_age
    )
  )
);

comment on table public.user_discovery_filters is
  'Optional discovery feed filters; one row per user.';

alter table public.user_discovery_filters enable row level security;

drop policy if exists "user_discovery_filters_select_own" on public.user_discovery_filters;
create policy "user_discovery_filters_select_own"
  on public.user_discovery_filters
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "user_discovery_filters_insert_own" on public.user_discovery_filters;
create policy "user_discovery_filters_insert_own"
  on public.user_discovery_filters
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "user_discovery_filters_update_own" on public.user_discovery_filters;
create policy "user_discovery_filters_update_own"
  on public.user_discovery_filters
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "user_discovery_filters_delete_own" on public.user_discovery_filters;
create policy "user_discovery_filters_delete_own"
  on public.user_discovery_filters
  for delete
  to authenticated
  using (user_id = auth.uid());

grant select, insert, update, delete on table public.user_discovery_filters to authenticated;
