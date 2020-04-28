-- Verify postgraphile_organizations:invite_to_organization on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('invite_to_organization(uuid,citext,citext)','execute');

ROLLBACK;
