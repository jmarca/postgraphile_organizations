-- Revert postgraphile_organizations:trigger_user_organization_delete_checks from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP TRIGGER _500_deletion_organization_checks_and_actions ON app_public.users;
DROP FUNCTION tg_users__deletion_organization_checks_and_actions();

COMMIT;
