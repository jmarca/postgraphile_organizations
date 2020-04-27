SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT pass('Test current_user_invited_organization_ids!');


-- create some test data
-- user
INSERT INTO app_public.users (username,name) VALUES ('jmarca', 'James E. Marca');

-- email
WITH uid(id) as (select id from app_public.users where username='jmarca')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'james@activimeowtricks.com', true from uid;

-- organization
INSERT INTO app_public.organizations (slug,name) VALUES ('Marca','The Marca Family');

-- invitation to membership
WITH uid(id) as (select id from app_public.users where username='jmarca'),
     oid(id) as (select id from app_public.organizations where slug='marca'::citext)
insert into app_public.organization_invitations (user_id, organization_id)
   select uid.id as user_id, oid.id as organization_id
   from uid
   join oid on (true);

WITH uid(id) as (select id from app_public.users where username='jmarca'),
     eml(user_id, email) as (select user_id, email from app_public.user_emails ue join uid on (uid.id=ue.user_id) where user_id=uid.id),
     oid(id) as (select id from app_public.organizations where slug='marca'::citext)
insert into app_public.organization_invitations (email, code, organization_id)
   select eml.email as email, 'blahblah code' as code,  oid.id as organization_id
   from eml
   join oid on (true);

-- while I'm here, check the table checks
prepare failing_insert as
WITH uid(id) as (select id from app_public.users where username='jmarca'),
     eml(user_id, email) as (select user_id, email from app_public.user_emails ue join uid on (uid.id=ue.user_id) where user_id=uid.id),
     oid(id) as (select id from app_public.organizations where slug='marca'::citext)
insert into app_public.organization_invitations (email, user_id, code, organization_id)
   select eml.email as email, eml.user_id as user_id, 'blahblah code' as code,  oid.id as organization_id
   from eml
   join oid on (true);

SELECT throws_ok(
    'failing_insert',
    '23514',
    'new row for relation "organization_invitations" violates check constraint "organization_invitations_check"',
    'Should fail to insert both a user_id and an email'
);


-- test --

-- without session, should not be able to select
SET ROLE :DATABASE_VISITOR;
select results_eq('select * from app_public.current_user_invited_organization_ids()',
                  $$VALUES ((null::uuid)) $$,
                  'Should not select anything if no session');

select is_empty('select id from app_public.organizations',
                  'Should not select anything if no session');

select is_empty('select organization_id from app_public.organization_invitations',
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
    where slug='marca'::citext;

prepare user_is as
    select id from app_public.users
    where username='jmarca';

SET ROLE :DATABASE_VISITOR;

select results_eq('select organization_id from app_public.organization_invitations order by organization_id limit 1',
                  'organization_is',
                  'Should get the marca organization id when invited to join');

select results_eq('select id from app_public.organizations',
                  'organization_is',
                  'Should select something from organizations if is session');

select isnt_empty('select id from app_public.organizations',
                  'Should select something from organizations if is session');

select results_eq('select id from app_public.organizations',
                  'organization_is',
                  'Should select something from organizations if is session');

select isnt_empty('select organization_id from app_public.organization_invitations',
                  'Should select from invitations if is session');



SELECT finish();
ROLLBACK;
