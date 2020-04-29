-- Deploy postgraphile_organizations:remove_from_organization to pg
-- requires: postgraphile_user_system:users
-- requires: postgraphile_user_system:current_user_id
-- requires: postgraphile_extensions:uuid-ossp
-- requires: organizations
-- requires: organization_memberships

BEGIN;

SET SEARCH_PATH TO app_public,public;
CREATE OR REPLACE FUNCTION remove_from_organization (
  organization_id uuid,
  user_id uuid) RETURNS VOID AS
$$
declare
  v_my_membership app_public.organization_memberships;
begin
  select * into v_my_membership
    from app_public.organization_memberships
    where organization_memberships.organization_id = remove_from_organization.organization_id
    and organization_memberships.user_id = app_public.current_user_id();

  if (v_my_membership is null) then
    -- I'm not a member of that organization
    return;
  elsif v_my_membership.is_owner and remove_from_organization.user_id <> app_public.current_user_id() then
    -- Delete it
  elsif v_my_membership.is_owner and remove_from_organization.user_id = app_public.current_user_id() then
    -- Not allowed to delete it
    return;
  elsif v_my_membership.user_id = user_id then
    -- Delete it
  else
    -- Not allowed to delete it
    return;
  end if;

  if v_my_membership.is_billing_contact then
    update app_public.organization_memberships
      set is_billing_contact = false
      where id = v_my_membership.id
      returning * into v_my_membership;
    update app_public.organization_memberships
      set is_billing_contact = true
      where organization_memberships.organization_id = remove_from_organization.organization_id
      and organization_memberships.is_owner;
  end if;

  delete from app_public.organization_memberships
    where organization_memberships.organization_id = remove_from_organization.organization_id
    and organization_memberships.user_id = remove_from_organization.user_id;

end;
$$ language plpgsql volatile security definer set search_path to pg_catalog, public, pg_temp;

COMMENT ON FUNCTION remove_from_organization (uuid, uuid) is
  E'Remove a user_id from an organization.  Will only work if the current user is trying to self-remove, or if the organization owner is removing the user.  Will not remove the organization owner user_id from the organization.  To do that, the owner must instead delete the organization.';





COMMIT;
