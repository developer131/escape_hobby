-- 반드시 내 계정에 해당하는 한 줄만 수정 후 실행하세요.
-- 가입 아이디가 username@users.escape-log.invalid 방식이면 아래처럼 아이디를 넣습니다.
-- 기존 이메일 계정이면 이메일 주소를 auth.users.email과 비교하도록 바꾸세요.
-- 이 SQL을 실행하기 전에 해당 계정이 Authentication > Users에 실제로 존재하는지 확인하세요.

update public.profiles p
set is_admin = true, is_approved = true
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('REPLACE_WITH_YOUR_LOGIN_ID@users.escape-log.invalid');

-- 확인: 결과가 정확히 내 계정 한 건인지 확인
select u.email, p.nickname, p.is_admin, p.is_approved
from public.profiles p
join auth.users u on u.id = p.id
where p.is_admin = true;
