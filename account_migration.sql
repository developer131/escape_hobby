-- 기존 테이블과 기록을 삭제하지 않는 계정 기능 보완 SQL
-- Supabase SQL Editor에서 실행하세요.
drop policy if exists "own profile read" on public.profiles;
create policy "own profile read" on public.profiles
for select to authenticated
using (id = (select auth.uid()));

drop policy if exists "own profile update" on public.profiles;
create policy "own profile update" on public.profiles
for update to authenticated
using (id = (select auth.uid()) and is_approved = true)
with check (id = (select auth.uid()) and is_approved = true);

revoke update on public.profiles from authenticated;
grant update (nickname) on public.profiles to authenticated;
