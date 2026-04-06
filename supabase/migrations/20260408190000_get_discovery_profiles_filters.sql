-- Discovery: optional gender + age filters (same semantics as zone lobby page RPC).

drop function if exists public.get_discovery_profiles(int);

create or replace function public.get_discovery_profiles(
  p_limit int default 20,
  p_gender_filter text default null,
  p_min_age int default null,
  p_max_age int default null
)
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
        inner join auth.users u on u.id = p.id
        where p.id <> v_uid
          and not exists (
            select 1
            from public.profile_interactions pi
            where pi.viewer_id = v_uid
              and pi.target_id = p.id
              and pi.swipe is not null
          )
          and (
            p_gender_filter is null
            or length(trim(p_gender_filter)) = 0
            or lower(trim(p_gender_filter)) = 'all'
            or (
              lower(trim(p_gender_filter)) = 'female'
              and lower(trim(coalesce(p.gender, ''))) in ('female', 'f', 'kadın', 'kadin')
            )
            or (
              lower(trim(p_gender_filter)) = 'male'
              and lower(trim(coalesce(p.gender, ''))) in ('male', 'm', 'erkek')
            )
            or (
              lower(trim(p_gender_filter)) = 'other'
              and not (lower(trim(coalesce(p.gender, ''))) in ('female', 'f', 'kadın', 'kadin'))
              and not (lower(trim(coalesce(p.gender, ''))) in ('male', 'm', 'erkek'))
            )
          )
          and (p_min_age is null or (p.age is not null and p.age >= p_min_age))
          and (p_max_age is null or (p.age is not null and p.age <= p_max_age))
        order by random()
        limit v_lim
      ) sub
    ),
    '[]'::jsonb
  );
end;
$$;

comment on function public.get_discovery_profiles(int, text, int, int) is
  'Random discovery profiles (profiles ⋈ auth.users), optional gender/age, excluding swiped.';

grant execute on function public.get_discovery_profiles(int, text, int, int) to authenticated;
