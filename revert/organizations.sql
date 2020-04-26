-- Revert postgraphile_organizations:organizations from pg

BEGIN;

SET search_path TO app_public,public;
DROP TABLE organizations;

COMMIT;
