-- Revert postgraphile_organizations:organizations_current_user_is_owner from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP FUNCTION organizations_current_user_is_owner(organizations);

COMMIT;
