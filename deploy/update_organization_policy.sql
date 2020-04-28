-- Deploy postgraphile_organizations:update_organization_policy to pg
-- requires: postgraphile_user_system:users
-- requires: organizations
-- requires: organization_memberships

BEGIN;

create policy update_owner on app_public.organizations for update using (exists(
  select 1
  from app_public.organization_memberships
  where organization_id = organizations.id
  and user_id = app_public.current_user_id()
  and is_owner is true
));



COMMIT;
