-- Deploy postgraphile_organizations:organizations to pg
-- requires: postgraphile_schemas:schemas
-- requires: postgraphile_extensions:uuid-ossp
-- requires: postgraphile_extensions:citext

BEGIN;

SET search_path TO app_public,public;

CREATE TABLE organizations (
      id uuid primary key NOT NULL  DEFAULT gen_random_uuid(),
      slug citext NOT NULL unique,
      name text NOT NULL ,
      created_at timestamp with time zone NOT NULL  DEFAULT now()
);
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
COMMIT;
