-- 관리자 승인 화면용 보안 설정
-- 먼저 ADMIN_BOOTSTRAP.sql에서 내 계정에만 is_admin=true를 설정한 뒤 이 파일을 실행하세요.

create or replace function public.is_admin_user()
returns boolean
language sql stable security definer
set search_path=''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.is_admin = true
  );
$$;

drop policy if exists "admin read all profiles" on public.profiles;
create policy "admin read all profiles"
on public.profiles for select to authenticated
using (public.is_admin_user());

-- 권한 변경은 RPC로만 수행. 일반 사용자가 자신의 승인/관리자 상태를 수정할 수 없도록 합니다.
create or replace function public.admin_set_approval(target_user_id uuid, approved boolean)
returns boolean
language plpgsql security definer
set search_path=''
as $$
begin
  if not public.is_admin_user() then
    raise exception 'admin only';
  end if;
  update public.profiles
     set is_approved = approved
   where id = target_user_id and is_admin = false;
  return found;
end;
$$;

revoke all on function public.admin_set_approval(uuid, boolean) from public;
grant execute on function public.admin_set_approval(uuid, boolean) to authenticated;
grant select on public.profiles to authenticated;


-- 관리자 전용: 방탈출 페이지의 프로필 정보만 삭제합니다.
-- Supabase Auth 로그인 계정은 삭제하지 않습니다.
create or replace function public.admin_delete_profile(target_user_id uuid)
returns boolean
language plpgsql security definer
set search_path=''
as $$
begin
  if not public.is_admin_user() then
    raise exception 'admin only';
  end if;
  delete from public.profiles
   where id = target_user_id and is_admin = false;
  return found;
end;
$$;

revoke all on function public.admin_delete_profile(uuid) from public;
grant execute on function public.admin_delete_profile(uuid) to authenticated;
