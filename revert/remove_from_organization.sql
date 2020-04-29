-- Revert postgraphile_organizations:remove_from_organization from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP FUNCTION remove_from_organization(uuid,uuid);

COMMIT;
