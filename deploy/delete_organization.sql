-- Deploy postgraphile_organizations:delete_organization to pg
-- requires: postgraphile_user_system:users
-- requires: postgraphile_user_system:current_user_id
-- requires: postgraphile_extensions:uuid-ossp
-- requires: organizations
-- requires: organization_memberships

BEGIN;

SET SEARCH_PATH TO app_public,public;
CREATE OR REPLACE FUNCTION delete_organization (
  organization_id uuid) RETURNS VOID AS
$$
begin
  if exists(
    select 1
    from app_public.organization_memberships
    where user_id = app_public.current_user_id()
    and organization_memberships.organization_id = delete_organization.organization_id
    and is_owner is true
  ) then
    delete from app_public.organizations where id = organization_id;
  end if;
end;
$$ language plpgsql volatile security definer set search_path to pg_catalog, public, pg_temp;


COMMENT ON FUNCTION delete_organization (uuid) is
  E'Delete an organization.  Calling user must be the organization owner';

COMMIT;
