SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT pass('Test transfer_organization_billing_contact!');

-- test your function --
-- create some test data
-- user
INSERT INTO app_public.users (username,name) VALUES ('jmarca', 'James E. Marca');
INSERT INTO app_public.users (username,name) VALUES ('farfalla', 'Kitty A. Katt');
INSERT INTO app_public.users (username,name) VALUES ('gd', 'Greece Doll');

-- email
WITH uid(id) as (select id from app_public.users where username='jmarca')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'james@activimeowtricks.com', true from uid;

WITH uid(id) as (select id from app_public.users where username='farfalla')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'farfalla@activimeowtricks.com', true from uid;

WITH uid(id) as (select id from app_public.users where username='gd')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'athena@activimeowtricks.com', true from uid;


-- organizations
INSERT INTO app_public.organizations (slug,name) VALUES ('Marca','The Marca Family');
INSERT INTO app_public.organizations (slug,name) VALUES ('pets','Household Pets');
INSERT INTO app_public.organizations (slug,name) VALUES ('dolls','Dolls and other servants');

-- make current members
WITH
o(id) as (select id from app_public.organizations where slug='marca'),
u(id) as (select id from app_public.users where username='jmarca')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, true, true
  from o
  join u on (true);

WITH
o(id) as (select id from app_public.organizations where slug='marca'),
u(id) as (select id from app_public.users where username='gd')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, false, false
  from o
  join u on (true);

WITH
o(id) as (select id from app_public.organizations where slug='pets'),
u(id) as (select id from app_public.users where username='farfalla')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, true, true
  from o
  join u on (true);

WITH
o(id) as (select id from app_public.organizations where slug='dolls'),
u(id) as (select id from app_public.users where username='gd')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, true, false
  from o
  join u on (true);

WITH
o(id) as (select id from app_public.organizations where slug='dolls'),
u(id) as (select id from app_public.users where username='jmarca')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, false, true
  from o
  join u on (true);

-- set up fake session

with uid(id) as (select id from app_public.users where username='jmarca')
insert into app_private.sessions (user_id)
   select uid.id  from uid;
-- fake jwt claims
with
uid(id) as (select id from app_public.users where username='jmarca'),
sid(uuid) as (select uuid from app_private.sessions s join uid u on (u.id=s.user_id))
select set_config('jwt.claims.session_id', sid.uuid::text, true)
from sid;

SET ROLE :DATABASE_VISITOR;

-- baseline


select results_eq('select username, is_billing_contact from app_public.organization_memberships om join app_public.users u on om.user_id=u.id join app_public.organizations o on (o.id=om.organization_id) where o.slug=' || quote_literal('dolls') ||'::citext  order by username',
       $$VALUES('gd'::citext, false), ('jmarca'::citext, true) $$,
       'Should be able to view that gd is billing contact, jmarca is not billing contact');

-- cannot transfer billing_contact of dolls group to jmarca (not current owner)
select results_eq(
'with
o(id) as (select id from app_public.organizations o where slug='
|| quote_literal('dolls')
|| '),
u(id) as (select id from app_public.users u where username='
|| quote_literal('gd')
|| ')
select app_public.transfer_organization_billing_contact(o.id,u.id)
from o join u on (true)',
$$VALUES ( NULL::organizations )$$,
'Should return empty set when trying to change billing_contact when not owner');

select results_eq('select username, is_billing_contact from app_public.organization_memberships om join app_public.users u on om.user_id=u.id join app_public.organizations o on (o.id=om.organization_id) where o.slug=' || quote_literal('dolls') ||'::citext  order by username',
       $$VALUES('gd'::citext, false), ('jmarca'::citext, true) $$,
       'Should be same as before for organization dolls');

-- now test org marca, which is owned by jmarca
select results_eq('select username, is_billing_contact from app_public.organization_memberships om join app_public.users u on om.user_id=u.id join app_public.organizations o on (o.id=om.organization_id) where o.slug=' || quote_literal('marca') ||'::citext  order by username',
       $$VALUES('gd'::citext, false), ('jmarca'::citext, true) $$,
       'Should be able to view that gd is not billing contact, jmarca is billing contact');


-- should not be able to transfer billing_contact to non-member
select results_eq(
'with
o(id) as (select id from app_public.organizations o where slug='
|| quote_literal('marca')
|| '),
u(id) as (select id from app_public.users u where username='
|| quote_literal('farfalla')
|| ')
select app_public.transfer_organization_billing_contact(o.id,u.id)
from o join u on (true)',
$$VALUES ( NULL::organizations )$$,
'Should return empty set when trying to change billing_contact to non-member');

select results_eq('select username, is_billing_contact from app_public.organization_memberships om join app_public.users u on om.user_id=u.id join app_public.organizations o on (o.id=om.organization_id) where o.slug=' || quote_literal('marca') ||'::citext  order by username',
       $$VALUES('gd'::citext, false), ('jmarca'::citext, true) $$,
       'Should be unchanged, as cannot transfer to non-member');

prepare organization_is as select (o.*) from app_public.organizations o where slug='marca';

-- now should successfully transfer to gd
select results_eq(
'with
o(id) as (select id from app_public.organizations o where slug='
|| quote_literal('marca')
|| '),
u(id) as (select id from app_public.users u where username='
|| quote_literal('gd')
|| ')
select ao.*
from  o, u, app_public.transfer_organization_billing_contact(o.id,u.id) ao',
'organization_is',
'Should return the organization when billing_contact is successfully changed');

select results_eq('select username, is_billing_contact from app_public.organization_memberships om join app_public.users u on om.user_id=u.id join app_public.organizations o on (o.id=om.organization_id) where o.slug=' || quote_literal('marca') ||'::citext  order by username',
       $$VALUES('gd'::citext, true), ('jmarca'::citext, false) $$,
       'Should have switched billing_contact from jmarca to gd');


SELECT finish();
ROLLBACK;
