-- Verify postgraphile_organizations:accept_invitation_to_organization on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('accept_invitation_to_organization(uuid,text)','execute');

ROLLBACK;
