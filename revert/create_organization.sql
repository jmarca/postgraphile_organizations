-- Revert postgraphile_organizations:create_organization from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP FUNCTION create_organization(citext,text);

COMMIT;
