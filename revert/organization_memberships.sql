-- Revert postgraphile_organizations:organization_memberships from pg

BEGIN;

SET search_path TO app_public,public;
DROP TABLE organization_memberships;

COMMIT;
