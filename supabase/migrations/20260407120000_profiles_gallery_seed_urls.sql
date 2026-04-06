-- Backfill profiles.gallery_urls with 3–5 placeholder images per row (deterministic seeds).
-- Uses picsum.photos; safe to re-run: only updates rows with no gallery yet.

update public.profiles p
set gallery_urls = (
  select coalesce(array_agg(u order by n), '{}')
  from (
    select
      n,
      'https://picsum.photos/seed/g'
        || substr(md5(p.id::text || '_' || n::text), 1, 16)
        || '/480/640' as u
    from generate_series(
      1,
      3 + mod(abs(hashtext(p.id::text)), 3)
    ) as n
  ) s
)
where coalesce(array_length(p.gallery_urls, 1), 0) = 0;

comment on column public.profiles.gallery_urls is
  'Additional public photo URLs (avatar_url remains the primary). Seeded with 3–5 picsum placeholders when empty.';
