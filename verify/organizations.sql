-- Verify postgraphile_organizations:organizations on pg

BEGIN;

SET search_path TO app_public,public;
SELECT id, slug, name, created_at
FROM organizations
WHERE FALSE;

ROLLBACK;
