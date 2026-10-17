-- Run once in Supabase SQL Editor before using the updated app.
-- Preserve existing records; old remaining_minutes values remain valid.
alter table public.shared_play_records
  add column if not exists remaining_seconds integer
  check (remaining_seconds is null or remaining_seconds between 0 and 10859);

alter table public.personal_play_records
  add column if not exists remaining_seconds integer
  check (remaining_seconds is null or remaining_seconds between 0 and 10859);

-- Existing rows are not rewritten. The app displays their old remaining_minutes
-- values as whole minutes until they are edited and saved in the new form.
