-- Revert postgraphile_organizations:delete_organization from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP FUNCTION delete_organization(uuid);

COMMIT;
