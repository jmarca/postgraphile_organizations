-- Deploy postgraphile_organizations:organization_for_invitation to pg
-- requires: invite_to_organization
-- requires: postgraphile_user_system:users
-- requires: organizations

BEGIN;

SET SEARCH_PATH TO app_public,public;
CREATE OR REPLACE FUNCTION organization_for_invitation (
  invitation_id uuid,
  code text = null) RETURNS app_public.organizations AS
$$
declare
  v_invitation app_public.organization_invitations;
  v_organization app_public.organizations;
begin
  if app_public.current_user_id() is null then
    raise exception 'You must log in to accept an invitation' using errcode = 'LOGIN';
  end if;

  select * into v_invitation from app_public.organization_invitations where id = invitation_id;

  if v_invitation is null then
    raise exception 'We could not find that invitation, or that invitation and code is not for you' using errcode = 'DNIED';
  end if;

  if v_invitation.user_id is not null then
    if v_invitation.user_id is distinct from app_public.current_user_id() then
      raise exception 'We could not find that invitation, or that invitation and code is not for you' using errcode = 'DNIED';
    end if;
  else
    if v_invitation.code is distinct from code then
      raise exception 'We could not find that invitation, or that invitation and code is not for you' using errcode = 'DNIED';
    end if;
  end if;

  select * into v_organization from app_public.organizations where id = v_invitation.organization_id;

  return v_organization;
end;
$$ language plpgsql stable security definer set search_path = pg_catalog, public, pg_temp;


COMMENT ON FUNCTION organization_for_invitation (uuid, text) is
  E'This function figures out which organization matches the given invitation id and code.  The invitation and code must match the current logged-in user.';


COMMIT;
