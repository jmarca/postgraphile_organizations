-- Verify postgraphile_organizations:organization_invitations on pg

BEGIN;

SET search_path TO app_public,public;
SELECT id, organization_id, code, user_id, email
FROM organization_invitations
WHERE FALSE;

ROLLBACK;
