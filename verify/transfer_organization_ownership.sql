-- Verify postgraphile_organizations:transfer_organization_ownership on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('transfer_organization_ownership(uuid,uuid)','execute');

ROLLBACK;
