SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SELECT pass('Test update_organization_policy!');
-- create some test data
-- user
INSERT INTO app_public.users (username,name) VALUES ('jmarca', 'James E. Marca');
INSERT INTO app_public.users (username,name) VALUES ('gd', 'Greece Doll');

-- email
WITH uid(id) as (select id from app_public.users where username='jmarca')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'james@activimeowtricks.com', true from uid;

WITH uid(id) as (select id from app_public.users where username='gd')
insert into app_public.user_emails (user_id, email, is_verified)
   select uid.id, 'athena@activimeowtricks.com', true from uid;


-- organizations
INSERT INTO app_public.organizations (slug,name) VALUES ('Marca','The Marca Family');
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

update app_public.organizations set slug='marcafam' where slug='Marca'::citext;

select results_eq('select slug from app_public.organizations order by slug',
       $$VALUES ('dolls'::citext), ('marcafam'::citext)$$,
       'should allow owner to change slug');

-- should not work for dolls

update app_public.organizations set slug='toydolls' where slug='dolls'::citext;
select results_eq('select slug from app_public.organizations order by slug',
       $$VALUES ('dolls'::citext), ('marcafam'::citext)$$,
     'Should fail to update table if not owner of organization');

set role postgres;

with uid(id) as (select id from app_public.users where username='gd')
insert into app_private.sessions (user_id)
   select uid.id  from uid;
-- fake jwt claims
with
uid(id) as (select id from app_public.users where username='gd'),
sid(uuid) as (select uuid from app_private.sessions s join uid u on (u.id=s.user_id))
select set_config('jwt.claims.session_id', sid.uuid::text, true)
from sid;

SET ROLE :DATABASE_VISITOR;

update app_public.organizations set slug='plantlovers' where slug='marcafam'::citext;

select results_eq('select slug from app_public.organizations order by slug',
       $$VALUES ('dolls'::citext), ('marcafam'::citext)$$,
       'Should fail to update table if not owner of organization');

-- should work for dolls

update app_public.organizations set slug='toydolls' where slug='dolls'::citext;
select results_eq('select slug from app_public.organizations order by slug',
       $$VALUES ('marcafam'::citext), ('toydolls'::citext)$$,
       'should allow owner to change slug');




SELECT finish();
ROLLBACK;
