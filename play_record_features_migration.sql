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
