SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT pass('Test accept_invitation_to_organization!');

-- test your function --
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

-- generate an invite

WITH oid(id) as (select id from app_public.organizations where slug='marca'::citext)
insert into app_public.organization_invitations (email, code, organization_id)
   select 'athena@activimeowtricks.com' as email, 'blahblah code' as code,  oid.id as organization_id
   from oid;

WITH oid(id) as (select id from app_public.organizations where slug='marca'::citext),
     u(id) as (select id from app_public.users where username='gd')
insert into app_public.organization_invitations (user_id, organization_id)
   select u.id as user_id,  oid.id as organization_id
   from oid
   join u on (true);

prepare happy_path_1 as
with
oid(id) as (select id from app_public.organizations where slug='marca'::citext),
invite(id) as (
   select oi.id
   from app_public.organization_invitations oi
   join oid on (oi.organization_id=oid.id)
   where oi.code='blahblah code')
select ao.*
from invite i,
app_public.accept_invitation_to_organization (i.id, 'blahblah code' ) ao;

prepare happy_path_2 as
with
oid(id) as (select id from app_public.organizations where slug='marca'::citext),
u(id) as (select id from app_public.users where username='gd'),
invite(id, uid) as (
   select oi.id, oi.user_id as uid
   from app_public.organization_invitations oi
   join oid on (oi.organization_id=oid.id)
   join u on oi.user_id=u.id)
select ao.*
from invite i,
app_public.accept_invitation_to_organization (i.id) ao;

prepare error_path_bad_code as
with
oid(id) as (select id from app_public.organizations where slug='marca'::citext),
invite(id) as (
   select oi.id
   from app_public.organization_invitations oi
   join oid on (oi.organization_id=oid.id))
select app_public.accept_invitation_to_organization (i.id, 'jumbla' )
from invite i;


prepare error_path_bad_invite as
select app_public.accept_invitation_to_organization ('87c9c8a3-7aa3-453d-a1ff-2ecda25820a6'::uuid, 'pluba' );


prepare is_member_of as
with
u(id) as (select id from app_public.users where username='gd')
select organization_id
from app_public.organization_memberships om
join u on (u.id = om.user_id);


prepare organization_is as select (o.id) from app_public.organizations o where slug='marca';

prepare invites_to_gd as
with
 u(id,email) as (
   select u.id, ue.email
   from app_public.users u
   join app_public.user_emails ue on (u.id=ue.user_id)
   where u.username='gd')
select *
from app_public.organization_invitations oi
join u on (oi.user_id=u.id or oi.email=u.email);

-- set up fake session for gd
with uid(id) as (select id from app_public.users where username='gd')
insert into app_private.sessions (user_id)
   select uid.id  from uid;
-- fake jwt claims
with
uid(id) as (select id from app_public.users where username='gd'),
sid(uuid) as (select uuid from app_private.sessions s join uid u on (u.id=s.user_id))
select set_config('jwt.claims.session_id', sid.uuid::text, true)
from sid;

-- switching ROLE will make test fail, as the selects need more privs
-- to find the correct invitation_id
--
-- SET ROLE :DATABASE_VISITOR;

select isnt_empty(
  'invites_to_gd',
  'should have two invites extant');

select throws_ok(
 'error_path_bad_invite',
 'DNIED',
 'We could not find that invitation, or that invitation and code is not for you',
 'Should reject because made up invite');

select throws_ok(
 'error_path_bad_code',
 'DNIED',
 'We could not find that invitation, or that invitation and code is not for you',
 'Should reject because bad code');

select lives_ok(
   'happy_path_1',
   'Should correctly match invite id and code with organization');

-- check that it worked
select results_eq(
   'is_member_of',
   'organization_is',
   'Should have joined the organization using email invite');

select isnt_empty(
  'invites_to_gd',
  'should still have one invite extant');


-- remove from organization so as to accept the other invite too
WITH
o(id) as (select id from app_public.organizations where slug='marca'),
u(id) as (select id from app_public.users where username='gd')
DELETE FROM app_public.organization_memberships om
WHERE om.user_id=(select id from u)
     AND om.organization_id=(select id from o);


select lives_ok(
   'happy_path_2',
   'Should correctly match invite id based on user_id with organization');

-- check that it worked
select results_eq(
   'is_member_of',
   'organization_is',
   'Should have joined the organization using user_id invite');

-- check that both invites are deleted
select is_empty(
   'invites_to_gd',
   'Should have deleted both invites');


SELECT finish();
ROLLBACK;
