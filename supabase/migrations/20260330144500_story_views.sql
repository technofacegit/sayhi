-- Story izlenme kayıtları (kullanıcı bazlı)

create table if not exists public.story_views (
  user_id uuid not null references auth.users (id) on delete cascade,
  story_group_id uuid not null references public.story_groups (id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (user_id, story_group_id)
);

alter table public.story_views enable row level security;

-- Her kullanıcı sadece kendi kayıtlarını görebilir ve yönetebilir
drop policy if exists "story_views_select_own" on public.story_views;
create policy "story_views_select_own"
on public.story_views
for select
using (auth.uid() = user_id);

drop policy if exists "story_views_insert_own" on public.story_views;
create policy "story_views_insert_own"
on public.story_views
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "story_views_delete_own" on public.story_views;
create policy "story_views_delete_own"
on public.story_views
for delete
to authenticated
using (auth.uid() = user_id);

