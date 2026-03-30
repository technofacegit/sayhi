-- Stories (ring groups) + slides için tablolar (USER-BAĞIMSIZ)
-- UI eşleşmesi:
-- - story_groups.ring_image_url  => Home strip avatar
-- - story_slides.image_url       => StoryViewerScreen full-screen slides

-- UUID üretimi için (Supabase projelerinde genelde zaten açık)
create extension if not exists pgcrypto;

-- Story ring grupları (user bağımsız)
create table if not exists public.story_groups (
  id uuid primary key default gen_random_uuid(),
  label text,
  ring_image_url text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours')
);

create index if not exists story_groups_expires_at_idx
  on public.story_groups(expires_at);

-- Story slides (bir ring için birden fazla slide)
create table if not exists public.story_slides (
  id uuid primary key default gen_random_uuid(),
  story_group_id uuid not null references public.story_groups(id) on delete cascade,
  slide_index integer not null,
  image_url text not null,
  created_at timestamptz not null default now(),
  unique (story_group_id, slide_index)
);

create index if not exists story_slides_story_group_id_idx
  on public.story_slides(story_group_id);

create index if not exists story_slides_story_group_slide_index_idx
  on public.story_slides(story_group_id, slide_index);

-- RLS etkinleştir
alter table public.story_groups enable row level security;
alter table public.story_slides enable row level security;

------------------------------------------------------------
-- READ POLICIES
------------------------------------------------------------

-- Sadece süresi dolmamış story ring’leri okunabilir
drop policy if exists "story_groups_select_non_expired" on public.story_groups;
create policy "story_groups_select_non_expired"
on public.story_groups
for select
using (expires_at > now());

-- Slide’lar: parent story non-expired ise okunabilir
drop policy if exists "story_slides_select_non_expired_parent" on public.story_slides;
create policy "story_slides_select_non_expired_parent"
on public.story_slides
for select
using (
  exists (
    select 1
    from public.story_groups g
    where g.id = story_slides.story_group_id
      and g.expires_at > now()
  )
);

------------------------------------------------------------
-- WRITE POLICIES (sadece authenticated, user_id şartı YOK)
------------------------------------------------------------

-- story_groups write
drop policy if exists "story_groups_write_authenticated_insert" on public.story_groups;
create policy "story_groups_write_authenticated_insert"
on public.story_groups
for insert
to authenticated
with check (auth.uid() is not null);

drop policy if exists "story_groups_write_authenticated_update" on public.story_groups;
create policy "story_groups_write_authenticated_update"
on public.story_groups
for update
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

drop policy if exists "story_groups_write_authenticated_delete" on public.story_groups;
create policy "story_groups_write_authenticated_delete"
on public.story_groups
for delete
to authenticated
using (auth.uid() is not null);

-- story_slides write
drop policy if exists "story_slides_write_authenticated_insert" on public.story_slides;
create policy "story_slides_write_authenticated_insert"
on public.story_slides
for insert
to authenticated
with check (auth.uid() is not null);

drop policy if exists "story_slides_write_authenticated_update" on public.story_slides;
create policy "story_slides_write_authenticated_update"
on public.story_slides
for update
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

drop policy if exists "story_slides_write_authenticated_delete" on public.story_slides;
create policy "story_slides_write_authenticated_delete"
on public.story_slides
for delete
to authenticated
using (auth.uid() is not null);

