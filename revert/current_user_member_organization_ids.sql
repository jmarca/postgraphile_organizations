-- Revert postgraphile_organizations:current_user_member_organization_ids from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;

DROP POLICY select_member on app_public.organizations;
DROP POLICY select_member on app_public.organization_memberships;

DROP FUNCTION current_user_member_organization_ids();
COMMIT;
