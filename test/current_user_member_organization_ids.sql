SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT pass('Test current_user_member_organization_ids!');

-- create some test data
-- user
INSERT INTO app_public.users (username,name) VALUES ('jmarca', 'James E. Marca');

-- email
WITH uid(id) as (select id from app_public.users where username='jmarca')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'james@activimeowtricks.com', true from uid;

-- organization
INSERT INTO app_public.organizations (slug,name) VALUES ('Marca','The Marca Family');

-- membership
WITH uid(id) as (select id from app_public.users where username='jmarca'),
     oid(id) as (select id from app_public.organizations where slug='marca'::citext)
insert into app_public.organization_memberships (user_id, organization_id)
   select uid.id as user_id, oid.id as organization_id
   from uid
   join oid on (true);


-- test --

-- without session, should not be able to select
SET ROLE :DATABASE_VISITOR;
select results_eq('select * from app_public.current_user_member_organization_ids()',
                  $$VALUES ((null::uuid)) $$,
                  'Should not select anything if no session');

select is_empty('select id from app_public.organizations',
                  'Should not select anything if no session');

select is_empty('select organization_id from app_public.organization_memberships',
                  'Should not select anything if no session');

-- set up fake session
SET ROLE postgres;
with uid(id) as (select id from app_public.users where username='jmarca')
insert into app_private.sessions (user_id)
   select uid.id  from uid;
-- fake jwt claims
with
uid(id) as (select id from app_public.users where username='jmarca'),
sid(uuid) as (select uuid from app_private.sessions s join uid u on (u.id=s.user_id))
select set_config('jwt.claims.session_id', sid.uuid::text, true)
from sid;

prepare organization_is as
    select id from app_public.organizations
    where slug='marca';

prepare user_is as
    select id from app_public.users
    where username='jmarca';

SET ROLE :DATABASE_VISITOR;
select isnt_empty('select id from app_public.organizations',
                  'Should select org id from organizations with valid session');

select isnt_empty('select organization_id from app_public.organization_memberships',
                  'Should select org id from organization_memberships with valid session');

select results_eq('select organization_id from app_public.organization_memberships',
                  'organization_is',
                  'Should get the marca organization id when is a member');


SELECT finish();
ROLLBACK;
