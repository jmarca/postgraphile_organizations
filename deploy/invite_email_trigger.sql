-- Deploy postgraphile_organizations:invite_email_trigger to pg
-- requires: invite_to_organization
-- requires: postgraphile_user_system:users
-- requires: organizations
-- requires: postgraphile_utility_functions:trigger_add_job

BEGIN;

create trigger _500_send_email after insert on app_public.organization_invitations
  for each row execute procedure app_private.tg__add_job('organization_invitations__send_invite');


COMMIT;
