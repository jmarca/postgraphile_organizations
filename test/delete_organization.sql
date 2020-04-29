SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT pass('Test delete_organization!');

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
  select o.id, u.id, true, true
  from o
  join u on (true);

WITH
o(id) as (select id from app_public.organizations where slug='dolls'),
u(id) as (select id from app_public.users where username='jmarca')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, false, false
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
select results_eq('select slug from app_public.organizations order by slug',
       $$VALUES ('dolls'::citext), ('marca'::citext)$$,
       'should see two organizations');

select results_eq('select username from app_public.organization_memberships om join app_public.users u on om.user_id=u.id join app_public.organizations o on (o.id=om.organization_id) where o.slug=' || quote_literal('marca') ||'::citext  order by username',
       $$VALUES(('gd'::citext)), (('jmarca'::citext)) $$,
       'Should be able to view the current members of an organization');

-- cannot delete dolls group

with
o(id) as (select id from app_public.organizations o where slug='dolls')
select app_public.delete_organization(o.id)
from o;

select results_eq('select slug from app_public.organizations order by slug',
       $$VALUES ('dolls'::citext), ('marca'::citext)$$,
       'should still see two organizations');

-- can delete marca group

with
o(id) as (select id from app_public.organizations o where slug='marca')
select app_public.delete_organization(o.id)
from o;

select results_eq('select slug from app_public.organizations order by slug',
       $$VALUES ('dolls'::citext)$$,
       'should just see dolls organization');

SELECT finish();
ROLLBACK;
