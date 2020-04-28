SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT pass('Test invite_to_organization!');

-- test your function --
SET search_path TO app_public,public;

SELECT pass('Test create_organization!');

-- create some test data
-- users
INSERT INTO app_public.users (username,name) VALUES ('jmarca', 'James E. Marca');
INSERT INTO app_public.users (username,name) VALUES ('farfalla', 'Kitty A. Katt');
INSERT INTO app_public.users (username,name) VALUES ('gd', 'Greece Doll');

-- emails
WITH uid(id) as (select id from app_public.users where username='jmarca')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'james@activimeowtricks.com', true from uid;

WITH uid(id) as (select id from app_public.users where username='farfalla')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'farfalla@activimeowtricks.com', true from uid;

WITH uid(id) as (select id from app_public.users where username='gd')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'athena@activimeowtricks.com', true from uid;

-- I could use the create_organization function here, but it would
-- require futzing with session ids, etc
--
-- so just do it the long way

-- organization 1, owned by jmarca
INSERT INTO app_public.organizations (slug,name) VALUES ('Marca','The Marca Family');

WITH
o(id) as (select id from app_public.organizations where slug='marca'),
u(id) as (select id from app_public.users where username='jmarca')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, true, true
  from o
  join u on (true);

-- organization 2, owned by farfalla
INSERT INTO app_public.organizations (slug,name) VALUES ('mousers','Domesticated Hunters');

WITH
o(id) as (select id from app_public.organizations where slug='mousers'),
u(id) as (select id from app_public.users where username='farfalla')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, true, true
  from o
  join u on (true);

-- make jmarca also a member
WITH
o(id) as (select id from app_public.organizations where slug='mousers'),
u(id) as (select id from app_public.users where username='jmarca')
INSERT INTO app_public.organization_memberships (organization_id, user_id)
  select o.id, u.id
  from o
  join u on (true);


-- set up fake session for jmarca
with uid(id) as (select id from app_public.users where username='jmarca')
insert into app_private.sessions (user_id)
   select uid.id  from uid;
-- fake jwt claims
with
uid(id) as (select id from app_public.users where username='jmarca'),
sid(uuid) as (select uuid from app_private.sessions s join uid u on (u.id=s.user_id))
select set_config('jwt.claims.session_id', sid.uuid::text, true)
from sid;

-- test cannot invite if not owner of organization
prepare failing_invite_1 as
with o(id) as (select id from app_public.organizations where slug='mousers')
select app_public.invite_to_organization(organization_id => o.id,username=>'gd'::citext)
from o;

-- -- ditto, but invite by email
prepare failing_invite_2 as
with o(id) as (select id from app_public.organizations where slug='mousers')
select app_public.invite_to_organization (organization_id=>o.id,email=>'athena@activimeowtricks.com')
from o;

prepare do_not_own as
select 1
from app_public.organization_memberships om
join organizations o on (o.id=om.organization_id)
join users u on (om.user_id=u.id)
where u.id = current_user_id()
and o.slug='mousers'
and om.is_owner;

SET ROLE :DATABASE_VISITOR;


select is_empty('do_not_own',
                'User jmarca should not own organization mousers');

SELECT throws_ok(
    'failing_invite_1',
    'DNIED',
    'You''re not the owner of this organization',
    'Should fail when not an owner, inviting by username'
);

SELECT throws_ok(
    'failing_invite_2',
    'DNIED',
    'You''re not the owner of this organization',
    'Should fail when not an owner, inviting by email'
);


SELECT finish();
ROLLBACK;
