-- 내 정보 화면에서 본인 닉네임만 수정할 수 있도록 설정
-- 기존 profiles 정책을 덮어쓰기 전에 현재 RLS 정책을 확인하세요.
DROP POLICY IF EXISTS "own profile update" ON public.profiles;
CREATE POLICY "own profile update"
ON public.profiles
FOR UPDATE TO authenticated
USING (id = (SELECT auth.uid()) AND is_approved = true)
WITH CHECK (id = (SELECT auth.uid()) AND is_approved = true);

REVOKE UPDATE ON public.profiles FROM authenticated;
GRANT UPDATE (nickname) ON public.profiles TO authenticated;
