-- Deploy postgraphile_organizations:current_user_invited_organization_ids to pg
-- requires: organization_invitations
-- requires: postgraphile_user_system:current_user_id

BEGIN;

SET SEARCH_PATH TO app_public,public;
CREATE OR REPLACE FUNCTION current_user_invited_organization_ids () RETURNS setof uuid AS
$$
  select organization_id from app_public.organization_invitations
    where user_id = app_public.current_user_id();
$$ language sql stable security definer set search_path = pg_catalog, public, pg_temp;

COMMENT ON FUNCTION current_user_invited_organization_ids () is
  E'This function will return the organization memberships for the current logged-in user.';

create policy select_invited on app_public.organizations
  for select using (id in (select app_public.current_user_invited_organization_ids()));

create policy select_invited on app_public.organization_invitations
  for select using (organization_id in (select app_public.current_user_invited_organization_ids()));





COMMIT;
