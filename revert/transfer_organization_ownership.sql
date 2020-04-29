-- Revert postgraphile_organizations:transfer_organization_ownership from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP FUNCTION transfer_organization_ownership(uuid,uuid);

COMMIT;
