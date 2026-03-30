-- E-posta ile giriş akışı: kayıtlı kullanıcı mı kontrolü (anon güvenli, satır sızdırmaz).
-- Çalıştırın: supabase db push veya SQL Editor'da çalıştırın.

alter table public.profiles
  add column if not exists email text;

create unique index if not exists profiles_email_lower_key
  on public.profiles (lower(trim(email)))
  where email is not null;

create or replace function public.profile_exists_by_email(lookup_email text)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from public.profiles p
    where p.email is not null
      and lower(trim(p.email)) = lower(trim(lookup_email))
  )
  or exists (
    select 1
    from auth.users u
    where u.email is not null
      and lower(trim(u.email)) = lower(trim(lookup_email))
  );
$$;

grant execute on function public.profile_exists_by_email(text) to anon, authenticated;
