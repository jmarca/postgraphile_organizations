-- Verify postgraphile_organizations:organizations_current_user_is_owner on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('organizations_current_user_is_owner(organizations)','execute');

ROLLBACK;
