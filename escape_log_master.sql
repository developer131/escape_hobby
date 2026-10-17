-- ESCAPE LOG: 통합 DB SQL
-- 이 파일 하나를 기준으로 관리합니다.
-- Supabase Dashboard > SQL Editor에서 실행하세요.
-- 주의: 현재 DB의 실제 적용 이력은 외부에서 확인할 수 없으므로, 실행 전 SQL Editor에서 오류 여부를 확인하세요.
-- 관리자 계정 지정은 맨 아래 ADMIN_BOOTSTRAP 부분의 아이디만 수정한 뒤 별도로 실행하는 것을 권장합니다.

-- [1] 테이블, 기본 함수, RLS 정책
create extension if not exists pgcrypto;
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,nickname text not null default '',is_approved boolean not null default false,is_admin boolean not null default false,created_at timestamptz not null default now());
create table if not exists public.groups(id uuid primary key default gen_random_uuid(),name text not null,created_by uuid not null references public.profiles(id),created_at timestamptz not null default now());
create table if not exists public.group_members(group_id uuid not null references public.groups(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,role text not null default 'member' check(role in('admin','member')),primary key(group_id,user_id));
create table if not exists public.themes(id uuid primary key default gen_random_uuid(),theme_name text not null,store_name text,region text,genre text,difficulty smallint check(difficulty between 1 and 5),horror_level smallint check(horror_level between 1 and 5),created_by uuid not null references public.profiles(id),created_at timestamptz not null default now());
create table if not exists public.shared_play_records(id uuid primary key default gen_random_uuid(),theme_id uuid not null references public.themes(id),played_at date,result text not null default 'unknown' check(result in('success','fail','unknown')),remaining_minutes integer check(remaining_minutes between 0 and 180),review text,created_by uuid not null references public.profiles(id),created_at timestamptz not null default now());
create table if not exists public.personal_play_records(id uuid primary key default gen_random_uuid(),theme_id uuid not null references public.themes(id),played_at date,result text not null default 'unknown' check(result in('success','fail','unknown')),remaining_minutes integer check(remaining_minutes between 0 and 180),review text,visibility text not null default 'private' check(visibility in('private','shared')),user_id uuid not null references public.profiles(id),created_at timestamptz not null default now());
create table if not exists public.wishlist_items(id uuid primary key default gen_random_uuid(),theme_id uuid not null references public.themes(id),note text,status text not null default 'want' check(status in('want','planned','played')),added_by uuid not null references public.profiles(id),created_at timestamptz not null default now());
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path='' as $$ begin insert into public.profiles(id,nickname,is_approved,is_admin) values(new.id,coalesce(new.raw_user_meta_data->>'nickname',split_part(coalesce(new.email,'member'),'@',1)),false,false) on conflict(id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
create or replace function public.is_approved_member() returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.is_approved=true); $$;
alter table public.profiles enable row level security; alter table public.groups enable row level security; alter table public.group_members enable row level security; alter table public.themes enable row level security; alter table public.shared_play_records enable row level security; alter table public.personal_play_records enable row level security; alter table public.wishlist_items enable row level security;
drop policy if exists "approved profiles read" on public.profiles;
create policy "approved profiles read" on public.profiles for select to authenticated using(public.is_approved_member());
drop policy if exists "own profile update" on public.profiles;
create policy "own profile update" on public.profiles for update to authenticated using(id=(select auth.uid()) and is_approved) with check(id=(select auth.uid()) and is_approved and is_admin=false);
revoke update on public.profiles from authenticated; grant update(nickname) on public.profiles to authenticated;
drop policy if exists "approved groups read" on public.groups;
create policy "approved groups read" on public.groups for select to authenticated using(public.is_approved_member());
drop policy if exists "approved group members read" on public.group_members;
create policy "approved group members read" on public.group_members for select to authenticated using(public.is_approved_member());
drop policy if exists "approved themes read" on public.themes;
create policy "approved themes read" on public.themes for select to authenticated using(public.is_approved_member());
drop policy if exists "approved themes insert" on public.themes;
create policy "approved themes insert" on public.themes for insert to authenticated with check(public.is_approved_member() and created_by=(select auth.uid()));
drop policy if exists "approved themes update" on public.themes;
create policy "approved themes update" on public.themes for update to authenticated using(public.is_approved_member()) with check(public.is_approved_member());
drop policy if exists "approved themes delete" on public.themes;
create policy "approved themes delete" on public.themes for delete to authenticated using(public.is_approved_member());
drop policy if exists "approved shared read" on public.shared_play_records;
create policy "approved shared read" on public.shared_play_records for select to authenticated using(public.is_approved_member());
drop policy if exists "approved shared insert" on public.shared_play_records;
create policy "approved shared insert" on public.shared_play_records for insert to authenticated with check(public.is_approved_member() and created_by=(select auth.uid()));
drop policy if exists "approved shared update" on public.shared_play_records;
create policy "approved shared update" on public.shared_play_records for update to authenticated using(public.is_approved_member()) with check(public.is_approved_member());
drop policy if exists "approved shared delete" on public.shared_play_records;
create policy "approved shared delete" on public.shared_play_records for delete to authenticated using(public.is_approved_member());
drop policy if exists "own or shared personal read" on public.personal_play_records;
create policy "own or shared personal read" on public.personal_play_records for select to authenticated using(public.is_approved_member() and (user_id=(select auth.uid()) or visibility='shared'));
drop policy if exists "own personal insert" on public.personal_play_records;
create policy "own personal insert" on public.personal_play_records for insert to authenticated with check(public.is_approved_member() and user_id=(select auth.uid()));
drop policy if exists "own personal update" on public.personal_play_records;
create policy "own personal update" on public.personal_play_records for update to authenticated using(public.is_approved_member() and user_id=(select auth.uid())) with check(public.is_approved_member() and user_id=(select auth.uid()));
drop policy if exists "own personal delete" on public.personal_play_records;
create policy "own personal delete" on public.personal_play_records for delete to authenticated using(public.is_approved_member() and user_id=(select auth.uid()));
drop policy if exists "approved wishlist read" on public.wishlist_items;
create policy "approved wishlist read" on public.wishlist_items for select to authenticated using(public.is_approved_member());
drop policy if exists "approved wishlist insert" on public.wishlist_items;
create policy "approved wishlist insert" on public.wishlist_items for insert to authenticated with check(public.is_approved_member() and added_by=(select auth.uid()));
drop policy if exists "approved wishlist update" on public.wishlist_items;
create policy "approved wishlist update" on public.wishlist_items for update to authenticated using(public.is_approved_member()) with check(public.is_approved_member());
drop policy if exists "approved wishlist delete" on public.wishlist_items;
create policy "approved wishlist delete" on public.wishlist_items for delete to authenticated using(public.is_approved_member());


-- [2] 관리자 승인/거부 기능
-- 관리자 승인 화면용 보안 설정
-- 관리자 권한은 아래 별도 관리자 지정 SQL에서 설정합니다.

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


-- [3] 플레이 기록 힌트/이미지 컬럼 및 Storage 정책
-- Run once in Supabase SQL Editor.
alter table public.shared_play_records add column if not exists hint_count integer not null default 0 check (hint_count between 0 and 99), add column if not exists image_paths text[] not null default '{}';
alter table public.personal_play_records add column if not exists hint_count integer not null default 0 check (hint_count between 0 and 99), add column if not exists image_paths text[] not null default '{}';
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types) values ('play-record-images','play-record-images',false,8388608,array['image/jpeg','image/png','image/webp','image/gif','image/heic']) on conflict(id) do update set public=false,file_size_limit=8388608;
drop policy if exists "approved members upload own play images" on storage.objects;
create policy "approved members upload own play images" on storage.objects for insert to authenticated with check (bucket_id='play-record-images' and (storage.foldername(name))[1]=(select auth.uid())::text and public.is_approved_member());
drop policy if exists "owners and shared records read play images" on storage.objects;
create policy "owners and shared records read play images" on storage.objects for select to authenticated using (bucket_id='play-record-images' and public.is_approved_member() and ((storage.foldername(name))[1]=(select auth.uid())::text or exists(select 1 from public.shared_play_records r where r.id::text=(storage.foldername(name))[2]) or exists(select 1 from public.personal_play_records r where r.id::text=(storage.foldername(name))[2] and r.visibility='shared')));
drop policy if exists "owners delete own play images" on storage.objects;
create policy "owners delete own play images" on storage.objects for delete to authenticated using (bucket_id='play-record-images' and (storage.foldername(name))[1]=(select auth.uid())::text and public.is_approved_member());


-- ============================================================
-- 관리자 지정 (실행 전 아래 아이디를 실제 가입 아이디로 바꾸세요)
-- 앱은 아이디를 ID@users.escape-log.invalid 형식으로 Supabase Auth에 저장합니다.
-- 이 UPDATE는 한 명의 관리자 계정만 지정합니다. 먼저 해당 계정으로 가입해야 합니다.
-- 아래 쿼리는 별도로 선택해서 실행하세요.
-- ============================================================
-- update public.profiles p
-- set is_admin = true, is_approved = true
-- from auth.users u
-- where p.id = u.id
--   and lower(u.email) = lower('REPLACE_WITH_YOUR_LOGIN_ID@users.escape-log.invalid');
-- select u.email, p.nickname, p.is_admin, p.is_approved
-- from public.profiles p join auth.users u on u.id=p.id where p.is_admin=true;
