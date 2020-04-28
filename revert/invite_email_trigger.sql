-- Revert postgraphile_organizations:invite_email_trigger from pg

BEGIN;

DROP TRIGGER _500_send_email ON app_public.organization_invitations;

COMMIT;
