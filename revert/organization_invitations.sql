-- Revert postgraphile_organizations:organization_invitations from pg

BEGIN;

SET search_path TO app_public,public;
DROP TABLE organization_invitations;

COMMIT;
