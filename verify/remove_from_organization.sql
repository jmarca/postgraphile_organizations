-- Verify postgraphile_organizations:remove_from_organization on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('remove_from_organization(uuid,uuid)','execute');

ROLLBACK;
