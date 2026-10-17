# ESCAPE LOG

방탈출 기록 앱: 공동 플레이 기록, 개인 플레이 기록(기본 비공개/선택 공개), 공동 위시리스트, 테마 목록.

## 기술
- HTML/CSS/JavaScript
- Supabase Auth + PostgreSQL + RLS
- GitHub Pages

## 시작
1. Supabase 프로젝트를 만듭니다.
2. `schema.sql`을 SQL Editor에서 실행합니다.
3. `app.js`의 `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`를 설정합니다. `service_role`/secret key는 브라우저에 넣지 마세요.
4. Authentication에서 공개 가입을 끄고 Dashboard의 Invite user로 멤버를 초대합니다.
5. README의 SQL 안내에 따라 관리자를 승인하고 모임을 구성합니다.
6. GitHub 저장소에 파일을 업로드하고 Settings → Pages에서 `main` / `/(root)`로 배포합니다.

## 파일
- index.html: 화면
- style.css: 모바일 우선 디자인
- app.js: 로그인, CRUD, 검색
- schema.sql: 테이블 및 RLS

관리자 초대/승인은 초기 버전에서 Supabase Dashboard에서 처리합니다. 서로 다른 두 계정으로 개인 기록 비공개 및 권한을 테스트한 후 사용하세요.
