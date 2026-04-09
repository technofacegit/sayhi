-- Localized language labels for translation language list.

alter table public.chat_translation_languages
  add column if not exists label_en text,
  add column if not exists label_tr text;

update public.chat_translation_languages
set
  label_en = case code
    when 'tr' then 'Turkish'
    when 'en' then 'English'
    when 'es' then 'Spanish'
    when 'de' then 'German'
    when 'fr' then 'French'
    when 'ar' then 'Arabic'
    when 'ru' then 'Russian'
    else label
  end,
  label_tr = case code
    when 'tr' then 'Türkçe'
    when 'en' then 'İngilizce'
    when 'es' then 'İspanyolca'
    when 'de' then 'Almanca'
    when 'fr' then 'Fransızca'
    when 'ar' then 'Arapça'
    when 'ru' then 'Rusça'
    else label
  end
where label_en is null or label_tr is null;

create or replace function public.get_chat_translation_languages(
  p_locale text default 'en'
)
returns jsonb
language sql
security definer
set search_path = public, auth
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'code', l.code,
        'label',
          case
            when lower(coalesce(p_locale, 'en')) like 'tr%' then coalesce(l.label_tr, l.label_en, l.label)
            else coalesce(l.label_en, l.label_tr, l.label)
          end
      )
      order by l.sort_order asc, l.code asc
    ),
    '[]'::jsonb
  )
  from public.chat_translation_languages l
  where l.is_enabled = true;
$$;

grant execute on function public.get_chat_translation_languages(text) to authenticated;
