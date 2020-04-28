-- Revert postgraphile_organizations:update_organization_policy from pg

BEGIN;

DROP POLICY update_owner on app_public.organizations;

COMMIT;
