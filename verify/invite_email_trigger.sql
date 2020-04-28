-- Verify postgraphile_organizations:invite_email_trigger on pg

BEGIN;

select 1/count(*)
from pg_trigger t
join pg_class c on (c.oid=t.tgrelid)
where c.relname='organization_invitations' and t.tgname='_500_send_email';


ROLLBACK;
