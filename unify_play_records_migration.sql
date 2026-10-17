-- ESCAPE LOG: team/personal play records -> one table
-- Run this in Supabase SQL Editor BEFORE deploying the updated frontend.
-- This migration copies existing rows and intentionally keeps the old tables for rollback.

create table if not exists public.play_records (
  id uuid primary key default gen_random_uuid(),
  record_type text not null check (record_type in ('team','personal')),
  theme_id uuid not null references public.themes(id),
  played_at date,
  result text not null default 'unknown' check (result in ('success','fail','unknown')),
  remaining_minutes integer check (remaining_minutes between 0 and 180),
  remaining_seconds integer check (remaining_seconds between 0 and 10800),
  hint_count integer not null default 0 check (hint_count between 0 and 99),
  review text,
  image_paths text[] not null default '{}',
  created_by uuid references public.profiles(id),
  user_id uuid not null references public.profiles(id),
  visibility text not null default 'private' check (visibility in ('private','shared')),
  created_at timestamptz not null default now()
);

alter table public.play_records add column if not exists record_type text;
alter table public.play_records add column if not exists remaining_seconds integer;
alter table public.play_records add column if not exists hint_count integer not null default 0;
alter table public.play_records add column if not exists image_paths text[] not null default '{}';
alter table public.play_records add column if not exists user_id uuid references public.profiles(id);
alter table public.play_records add column if not exists visibility text not null default 'private';

-- Team records: preserve their IDs and map created_by to both author fields.
insert into public.play_records
  (id, record_type, theme_id, played_at, result, remaining_minutes, remaining_seconds,
   hint_count, review, image_paths, created_by, user_id, visibility, created_at)
select id, 'team', theme_id, played_at, result, remaining_minutes,
       coalesce(remaining_seconds, case when remaining_minutes is null then null else remaining_minutes * 60 end),
       coalesce(hint_count,0), review, coalesce(image_paths,'{}'), created_by, created_by,
       'shared', created_at
from public.shared_play_records
on conflict (id) do nothing;

-- Personal records: retain IDs unless a UUID collision with a team record exists.
insert into public.play_records
  (id, record_type, theme_id, played_at, result, remaining_minutes, remaining_seconds,
   hint_count, review, image_paths, created_by, user_id, visibility, created_at)
select case when exists (select 1 from public.shared_play_records s where s.id=p.id)
            then gen_random_uuid() else p.id end,
       'personal', p.theme_id, p.played_at, p.result, p.remaining_minutes,
       coalesce(p.remaining_seconds, case when p.remaining_minutes is null then null else p.remaining_minutes * 60 end),
       coalesce(p.hint_count,0), p.review, coalesce(p.image_paths,'{}'), p.user_id,
       p.user_id, coalesce(p.visibility,'private'), p.created_at
from public.personal_play_records p
where not exists (
  select 1 from public.play_records r
  where r.id=p.id and r.record_type='personal' and r.user_id=p.user_id
)
on conflict (id) do nothing;

-- Add indexes for the main filters and ordering.
create index if not exists play_records_type_played_at_idx on public.play_records(record_type, played_at desc);
create index if not exists play_records_user_played_at_idx on public.play_records(user_id, played_at desc);

alter table public.play_records enable row level security;
drop policy if exists "play records read" on public.play_records;
drop policy if exists "play records insert" on public.play_records;
drop policy if exists "play records update" on public.play_records;
drop policy if exists "play records delete" on public.play_records;
create policy "play records read" on public.play_records for select to authenticated
using (public.is_approved_member() and (record_type='team' or user_id=(select auth.uid()) or visibility='shared'));
create policy "play records insert" on public.play_records for insert to authenticated
with check (public.is_approved_member() and user_id=(select auth.uid()) and created_by=(select auth.uid()));
create policy "play records update" on public.play_records for update to authenticated
using (public.is_approved_member() and (user_id=(select auth.uid()) or record_type='team'))
with check (public.is_approved_member() and user_id=(select auth.uid()) and created_by=(select auth.uid()));
create policy "play records delete" on public.play_records for delete to authenticated
using (public.is_approved_member() and (user_id=(select auth.uid()) or record_type='team'));

-- Update image read policy to point at the unified table.
drop policy if exists "owners and shared records read play images" on storage.objects;
create policy "owners and shared records read play images" on storage.objects for select to authenticated
using (bucket_id='play-record-images' and public.is_approved_member() and (
  (storage.foldername(name))[1]=(select auth.uid())::text
  or exists(select 1 from public.play_records r where r.id::text=(storage.foldername(name))[2]
    and (r.record_type='team' or r.user_id=(select auth.uid()) or r.visibility='shared'))
));

-- Verification queries; compare counts before dropping old tables (do not drop them yet).
select 'shared_play_records' as source, count(*) as row_count from public.shared_play_records
union all select 'personal_play_records', count(*) from public.personal_play_records
union all select 'play_records_team', count(*) from public.play_records where record_type='team'
union all select 'play_records_personal', count(*) from public.play_records where record_type='personal';
