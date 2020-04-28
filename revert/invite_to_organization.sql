-- Revert postgraphile_organizations:invite_to_organization from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP FUNCTION invite_to_organization(uuid,citext,citext);

COMMIT;
