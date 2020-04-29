-- Verify postgraphile_organizations:delete_organization on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('delete_organization(uuid)','execute');

ROLLBACK;
