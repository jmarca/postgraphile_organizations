SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT pass('Test organization_for_invitation!');

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

-- -- make farfalla also a member
-- WITH
-- o(id) as (select id from app_public.organizations where slug='marca'),
-- u(id) as (select id from app_public.users where username='farfalla')
-- INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
--   select o.id, u.id, false, false
--   from o
--   join u on (true);


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
app_public.organization_for_invitation (i.id, 'blahblah code' ) ao;

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
app_public.organization_for_invitation (i.id) ao;

prepare error_path_bad_code as
with
oid(id) as (select id from app_public.organizations where slug='marca'::citext),
invite(id) as (
   select oi.id
   from app_public.organization_invitations oi
   join oid on (oi.organization_id=oid.id))
select app_public.organization_for_invitation (i.id )
from invite i;


prepare error_path_bad_invite as
select app_public.organization_for_invitation ('87c9c8a3-7aa3-453d-a1ff-2ecda25820a6'::uuid, 'pluba' );


prepare organization_is as select (o.*) from app_public.organizations o where slug='marca';



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

--SET ROLE :DATABASE_VISITOR;

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

select results_eq(
   'happy_path_1',
   'organization_is',
   'Should correctly match invite id and code with organization');

select results_eq(
   'happy_path_2',
   'organization_is',
   'Should correctly match invite id based on user_id with organization');


-- SET ROLE postgres;

-- change session

-- set up fake session for gd
with uid(id) as (select id from app_public.users where username='farfalla')
insert into app_private.sessions (user_id)
   select uid.id  from uid;
-- fake jwt claims
with
uid(id) as (select id from app_public.users where username='farfalla'),
sid(uuid) as (select uuid from app_private.sessions s join uid u on (u.id=s.user_id))
select set_config('jwt.claims.session_id', sid.uuid::text, true)
from sid;

-- SET ROLE :DATABASE_VISITOR;

select throws_ok(
 'happy_path_2',
 'DNIED',
 'We could not find that invitation, or that invitation and code is not for you',
 'Should reject because wrong user');



SELECT finish();
ROLLBACK;
