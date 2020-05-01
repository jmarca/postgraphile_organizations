-- Deploy postgraphile_organizations:trigger_user_organization_delete_checks to pg
-- requires: postgraphile_user_system:users
-- requires: postgraphile_user_system:current_user_id
-- requires: postgraphile_extensions:uuid-ossp
-- requires: organizations
-- requires: organization_memberships

BEGIN;

SET SEARCH_PATH TO app_public,public;
CREATE OR REPLACE FUNCTION tg_users__deletion_organization_checks_and_actions () RETURNS trigger AS
$$
begin
  -- Check they're not an organization owner
  if exists(
    select 1
    from app_public.organization_memberships
    where user_id = app_public.current_user_id()
    and is_owner is true
  ) then
    raise exception 'You cannot delete your account until you are not the owner of any organizations.' using errcode = 'OWNER';
  end if;

  -- Reassign billing contact status back to the organization owner
  update app_public.organization_memberships
    set is_billing_contact = true
    where is_owner = true
    and organization_id in (
      select organization_id
      from app_public.organization_memberships my_memberships
      where my_memberships.user_id = app_public.current_user_id()
      and is_billing_contact is true
    );

  return old;
end;
$$ language plpgsql;

COMMENT ON FUNCTION tg_users__deletion_organization_checks_and_actions () is
  E'A function to use as a trigger to prevent deleting a user when the user is an owner of an organization.  In order to delete such a user, the ownership(s) must be transferred, or else the organization(s) must be deleted.';

create trigger _500_deletion_organization_checks_and_actions
  before delete
  on app_public.users
  for each row
  when (app_public.current_user_id() is not null)
  execute procedure app_public.tg_users__deletion_organization_checks_and_actions();




COMMIT;
