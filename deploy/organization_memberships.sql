-- Deploy postgraphile_organizations:organization_memberships to pg
-- requires: organizations
-- requires: postgraphile_user_system:users
-- requires: postgraphile_schemas:schemas
-- requires: postgraphile_extensions:uuid-ossp
-- requires: postgraphile_extensions:citext

BEGIN;

SET search_path TO app_public,public;

CREATE TABLE organization_memberships (
      id uuid primary key NOT NULL  DEFAULT gen_random_uuid(),
      organization_id uuid NOT NULL references app_public.organizations on delete cascade,
      user_id uuid NOT NULL references app_public.users on delete cascade,
      is_owner boolean NOT NULL  DEFAULT false,
      is_billing_contact boolean NOT NULL  DEFAULT false,
      created_at timestamp with time zone NOT NULL  DEFAULT now(),
      unique (organization_id, user_id)
);
ALTER TABLE organization_memberships ENABLE ROW LEVEL SECURITY;

create index on app_public.organization_memberships (user_id);

grant select on app_public.organization_memberships to :DATABASE_VISITOR;

COMMIT;
