수정 사항
- 공동/개인 플레이 기록에 사용한 힌트 수 필드 추가
- 플레이 기록당 이미지 최대 2장 첨부 (장당 8MB 이하)
- 이미지는 비공개 Supabase Storage 버킷에 저장하고 서명 URL로 표시
- '테마 목록' 메뉴/화면 제거. 기록 입력 시 테마명·매장·지역 직접 입력. 기존 테마 테이블과 기록 연결은 유지

적용 순서
1. Supabase Dashboard > SQL Editor에서 play_record_features_migration.sql 실행
2. GitHub Pages 저장소에 index.html, app.js, style.css 반영
3. 기존 Supabase 프로젝트 그대로 사용

주의: SQL 마이그레이션과 새 프런트엔드가 모두 적용돼야 힌트 수/이미지 저장이 동작합니다. 기존 테마 데이터는 삭제하지 않고 화면만 숨겼습니다.
