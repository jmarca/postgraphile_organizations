-- Verify postgraphile_organizations:update_organization_policy on pg

BEGIN;

select 1/count(*)
from pg_policy p
join pg_class c on (c.oid=p.polrelid)
where c.relname='organizations' and p.polname='update_owner';

ROLLBACK;
