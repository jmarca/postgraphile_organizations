-- Verify postgraphile_organizations:organization_memberships on pg

BEGIN;

SET search_path TO app_public,public;
SELECT id, organization_id, user_id, is_owner, is_billing_contact, created_at
FROM organization_memberships
WHERE FALSE;

ROLLBACK;
