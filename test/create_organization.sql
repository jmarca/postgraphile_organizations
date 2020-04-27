SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT pass('Test create_organization!');

-- create some test data
-- user
INSERT INTO app_public.users (username,name) VALUES ('jmarca', 'James E. Marca');

-- email
WITH uid(id) as (select id from app_public.users where username='jmarca')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'james@activimeowtricks.com', true from uid;

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
    where slug='_test_marca'::citext;

prepare organization_ownership_is as
    select om.user_id, om.is_owner, om.is_billing_contact
    from app_public.organizations o
    join app_public.organization_memberships om on (o.id=om.organization_id)
    where o.slug='_test_marca'::citext;

prepare create_call as
    select app_public.create_organization('_test_marca', 'The Marca Family');


SET ROLE :DATABASE_VISITOR;

SELECT lives_ok('create_call',
                'should not crash when calling create_organization');

select isnt_empty('organization_is',
                  'should have created a new organization');

select results_eq('organization_ownership_is',
                  $$VALUES (app_public.current_user_id(), true, true) $$,
                  'Should add membership, ownership, and billing contact when creating organization');



SELECT finish();
ROLLBACK;
