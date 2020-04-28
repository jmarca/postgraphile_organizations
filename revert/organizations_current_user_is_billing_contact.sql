-- Revert postgraphile_organizations:organizations_current_user_is_billing_contact from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP FUNCTION organizations_current_user_is_billing_contact(organizations);

COMMIT;
