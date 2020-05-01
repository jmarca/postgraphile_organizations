-- Verify postgraphile_organizations:trigger_user_organization_delete_checks on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('tg_users__deletion_organization_checks_and_actions()','execute');


select 1/count(*)
from pg_trigger t
join pg_class c on (c.oid=t.tgrelid)
where c.relname='users' and t.tgname='_500_deletion_organization_checks_and_actions';

ROLLBACK;
