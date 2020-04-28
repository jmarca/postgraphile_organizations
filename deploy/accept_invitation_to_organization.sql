-- Deploy postgraphile_organizations:accept_invitation_to_organization to pg
-- requires: invite_to_organization
-- requires: postgraphile_user_system:users
-- requires: organizations

BEGIN;

SET SEARCH_PATH TO app_public,public;
CREATE OR REPLACE FUNCTION accept_invitation_to_organization (
  invitation_id uuid,
  code text = NULL) RETURNS VOID AS
$$
declare
  v_organization app_public.organizations;
begin
  v_organization = app_public.organization_for_invitation(invitation_id, code);

  -- Accept the user into the organization
  insert into app_public.organization_memberships (organization_id, user_id)
    values(v_organization.id, app_public.current_user_id())
    on conflict do nothing;

  -- Delete the invitation
  delete from app_public.organization_invitations where id = invitation_id;
end;
$$ language plpgsql volatile security definer set search_path = pg_catalog, public, pg_temp;

COMMENT ON FUNCTION accept_invitation_to_organization (uuid, text) is
  E' some comment ';





COMMIT;
