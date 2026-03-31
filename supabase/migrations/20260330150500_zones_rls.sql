-- Basic RLS for zones table (readable by all, write restricted to authenticated)

alter table public.zones enable row level security;

drop policy if exists "zones_select_all" on public.zones;
create policy "zones_select_all"
on public.zones
for select
using (true);

drop policy if exists "zones_write_authenticated" on public.zones;
create policy "zones_write_authenticated"
on public.zones
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

