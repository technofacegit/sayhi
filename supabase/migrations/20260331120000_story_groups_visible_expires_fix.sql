-- Story'lerin ekranda görünmemesinin yaygın nedeni: RLS `expires_at > now()` ve
-- tablodaki satırların süresinin dolmuş olması. Politikayı genişletir ve süresi
-- geçmiş satırların okunabilir olması için expires_at'i yenileriz.

-- 1) Okuma politikaları: süre yoksa veya gelecekteyse okunabilir
drop policy if exists "story_groups_select_non_expired" on public.story_groups;
create policy "story_groups_select_non_expired"
on public.story_groups
for select
using (expires_at is null or expires_at > now());

drop policy if exists "story_slides_select_non_expired_parent" on public.story_slides;
create policy "story_slides_select_non_expired_parent"
on public.story_slides
for select
using (
  exists (
    select 1
    from public.story_groups g
    where g.id = story_slides.story_group_id
      and (g.expires_at is null or g.expires_at > now())
  )
);

-- 2) Mevcut veri: süresi geçmiş grupları yenile (1 yıl; içerik tekrar görünür olsun)
update public.story_groups
set expires_at = now() + interval '365 days'
where expires_at is not null
  and expires_at <= now();
