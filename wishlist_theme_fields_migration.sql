-- ESCAPE LOG: 위시리스트 우선순위/예상 금액 컬럼
-- Supabase Dashboard > SQL Editor에서 한 번 실행하세요.
-- 기존 데이터는 유지됩니다.
alter table public.wishlist_items
  add column if not exists priority integer not null default 0,
  add column if not exists estimated_cost integer
    check (estimated_cost is null or estimated_cost >= 0);

-- 테마 장르/난이도/공포도 컬럼은 기본 스키마에 이미 있으므로 추가하지 않습니다.
-- 단, 현재 운영 DB에 없을 수도 있어 누락된 경우에만 추가합니다.
alter table public.themes
  add column if not exists genre text,
  add column if not exists difficulty smallint check (difficulty between 1 and 5),
  add column if not exists horror_level smallint check (horror_level between 1 and 5);

-- 기존 위시 항목의 표시 순서를 초기화합니다.
with ranked as (
  select id, row_number() over (order by created_at asc, id) as n
  from public.wishlist_items
  where priority = 0
)
update public.wishlist_items w set priority = ranked.n
from ranked where w.id = ranked.id;
