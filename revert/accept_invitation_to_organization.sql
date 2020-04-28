-- Revert postgraphile_organizations:accept_invitation_to_organization from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP FUNCTION accept_invitation_to_organization(uuid,text);

COMMIT;
