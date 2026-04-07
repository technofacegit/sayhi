-- Allow users to read incoming likes (target_id = auth.uid) for likes badge/realtime.

drop policy if exists "profile_interactions_select_own" on public.profile_interactions;

create policy "profile_interactions_select_own"
  on public.profile_interactions for select
  using (
    viewer_id = auth.uid()
    or target_id = auth.uid()
  );
