-- Story slide başlık ve metin alanları (opsiyonel)

alter table public.story_slides
  add column if not exists title text,
  add column if not exists body text;

