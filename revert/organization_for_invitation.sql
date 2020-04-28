-- Revert postgraphile_organizations:organization_for_invitation from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP FUNCTION organization_for_invitation(uuid,text);

COMMIT;
