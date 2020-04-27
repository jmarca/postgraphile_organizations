-- Deploy postgraphile_organizations:create_organization to pg
-- requires: organizations

BEGIN;

SET SEARCH_PATH TO app_public,public;
CREATE OR REPLACE FUNCTION create_organization (
  slug citext,
  name text) RETURNS app_public.organizations AS
$$
declare
  v_org app_public.organizations;
begin
  insert into app_public.organizations (slug, name) values (slug, name) returning * into v_org;
  insert into app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
    values(v_org.id, app_public.current_user_id(), true, true);
  return v_org;
end;
$$ language plpgsql volatile security definer set search_path = pg_catalog, public, pg_temp;

COMMENT ON FUNCTION create_organization (citext, text) is
  E'Create a new organizations table entry, given a lowercase slug and an organization name.  The creating user will become the owner and contact person of the new organization.';





COMMIT;
