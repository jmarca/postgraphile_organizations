-- Verify postgraphile_organizations:create_organization on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('create_organization(citext,text)','execute');

ROLLBACK;
