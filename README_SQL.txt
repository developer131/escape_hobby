ESCAPE LOG 통합 SQL

파일: escape_log_master.sql

Supabase Dashboard > SQL Editor에서 실행합니다. GitHub에 올리는 것만으로 DB에 적용되지 않습니다.

중요:
- 이 파일은 확인 가능한 기존 프로젝트 SQL을 통합한 것입니다. Supabase DB의 현재 적용 이력은 직접 조회할 수 없으므로, 실행 후 오류가 나오면 오류 문구를 기준으로 조정해야 합니다.
- 관리자 지정 SQL은 파일 맨 아래에 주석 처리되어 있습니다. 실제 로그인 ID로 바꾼 후 별도로 선택해 실행하세요.
- 이 SQL은 public.profiles 행만 삭제하는 admin_delete_profile 함수를 포함합니다. Supabase Auth 계정은 삭제하지 않습니다.
- 기본 테이블을 생성하고 정책을 재생성하는 구문이 포함되어 있습니다. 테이블의 기존 데이터는 DROP하지 않습니다.
