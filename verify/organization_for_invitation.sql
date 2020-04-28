-- Verify postgraphile_organizations:organization_for_invitation on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('organization_for_invitation(uuid,text)','execute');

ROLLBACK;
