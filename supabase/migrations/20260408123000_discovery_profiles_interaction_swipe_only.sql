-- Discovery: only exclude profiles the viewer has already swiped (like/dislike).
-- Rows in profile_interactions with swipe IS NULL (e.g. favorite-only or cleared like)
-- must not hide the profile from the home deck.

create or replace function public.get_discovery_profiles(p_limit int default 20)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid;
  v_lim int;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Authentication required'
      using errcode = 'P0001';
  end if;

  v_lim := coalesce(nullif(p_limit, 0), 20);
  if v_lim < 1 then
    v_lim := 20;
  end if;
  if v_lim > 100 then
    v_lim := 100;
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'user_id', sub.id,
          'display_name', coalesce(sub.name, 'Member'),
          'bio', coalesce(sub.bio, ''),
          'age', sub.age,
          'gender', sub.gender,
          'avatar_url', sub.avatar_url,
          'gallery_urls', coalesce(sub.gallery_urls, '{}')
        )
      )
      from (
        select p.id, p.name, p.bio, p.age, p.gender, p.avatar_url, p.gallery_urls
        from public.profiles p
        where p.id <> v_uid
          and not exists (
            select 1
            from public.profile_interactions pi
            where pi.viewer_id = v_uid
              and pi.target_id = p.id
              and pi.swipe is not null
          )
        order by random()
        limit v_lim
      ) sub
    ),
    '[]'::jsonb
  );
end;
$$;

comment on function public.get_discovery_profiles(int) is
  'Random profiles excluding self and anyone the viewer has already swiped (like/dislike).';
