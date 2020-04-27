-- Deploy postgraphile_organizations:organization_invitations to pg
-- requires: organizations
-- requires: postgraphile_user_system:users
-- requires: postgraphile_schemas:schemas
-- requires: postgraphile_extensions:uuid-ossp
-- requires: postgraphile_extensions:citext

BEGIN;

SET search_path TO app_public,public;

CREATE TABLE organization_invitations (
      id uuid primary key NOT NULL  DEFAULT gen_random_uuid(),
      organization_id uuid NOT NULL references app_public.organizations on delete cascade,
      code text,
      user_id uuid references app_public.users on delete cascade,
      email citext,
      check ((user_id is null) <> (email is null)),
      check ((code is null) = (email is null)),
      unique (organization_id, user_id),
      unique (organization_id, email)
);
ALTER TABLE organization_invitations ENABLE ROW LEVEL SECURITY;

create index on app_public.organization_invitations(user_id);
grant select on app_public.organization_invitations to :DATABASE_VISITOR;

COMMIT;
