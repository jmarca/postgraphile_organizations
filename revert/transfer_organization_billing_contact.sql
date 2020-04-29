-- Revert postgraphile_organizations:transfer_organization_billing_contact from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP FUNCTION transfer_organization_billing_contact(uuid,uuid);

COMMIT;
