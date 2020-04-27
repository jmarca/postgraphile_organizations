-- Revert postgraphile_organizations:current_user_invited_organization_ids from pg

BEGIN;

SET SEARCH_PATH TO app_public,public;


DROP POLICY select_invited on app_public.organizations;
DROP POLICY select_invited on app_public.organization_invitations;
DROP FUNCTION current_user_invited_organization_ids();

COMMIT;
