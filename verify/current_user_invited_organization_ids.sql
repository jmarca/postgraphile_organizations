-- Verify postgraphile_organizations:current_user_invited_organization_ids on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('current_user_invited_organization_ids()','execute');

-- verify policies
select 1/count(*)
from pg_policy p
join pg_class c on (c.oid=p.polrelid)
where c.relname='organizations' and p.polname='select_invited';

select 1/count(*)
from pg_policy p
join pg_class c on (c.oid=p.polrelid)
where c.relname='organization_invitations' and p.polname='select_invited';
ROLLBACK;
