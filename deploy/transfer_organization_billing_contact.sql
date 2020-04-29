-- Deploy postgraphile_organizations:transfer_organization_billing_contact to pg
-- requires: postgraphile_user_system:users
-- requires: postgraphile_user_system:current_user_id
-- requires: postgraphile_extensions:uuid-ossp
-- requires: organizations
-- requires: organization_memberships

BEGIN;

SET SEARCH_PATH TO app_public,public;
CREATE OR REPLACE FUNCTION transfer_organization_billing_contact (
  organization_id uuid,
  user_id uuid) RETURNS app_public.organizations AS
$$
declare
 v_org app_public.organizations;
begin
  if exists(
    select 1
    from app_public.organization_memberships
    where organization_memberships.user_id = app_public.current_user_id()
    and organization_memberships.organization_id = transfer_organization_billing_contact.organization_id
    and is_owner is true
  ) then
    update app_public.organization_memberships
      set is_billing_contact = true
      where organization_memberships.organization_id = transfer_organization_billing_contact.organization_id
      and organization_memberships.user_id = transfer_organization_billing_contact.user_id;
    if found then
      update app_public.organization_memberships
        set is_billing_contact = false
        where organization_memberships.organization_id = transfer_organization_billing_contact.organization_id
        and organization_memberships.user_id <> transfer_organization_billing_contact.user_id
        and is_billing_contact = true;

      select * into v_org from app_public.organizations where id = organization_id;
      return v_org;
    end if;
  end if;
  return null;
end;
$$ language plpgsql volatile security definer set search_path to pg_catalog, public, pg_temp;

COMMENT ON FUNCTION transfer_organization_billing_contact (uuid, uuid) is
  E'Function to transfer organization billing contact from one user to another.  Must be called by the current owner''s account.  The new billing contact must already be a member of the organization.';






COMMIT;
