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

-- make farfall also a member
WITH
o(id) as (select id from app_public.organizations where slug='marca'),
u(id) as (select id from app_public.users where username='farfalla')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, false, false
  from o
  join u on (true);



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


WITH uid(id) as (select id from app_public.users where username='gd'),
     eml(user_id, email) as (select user_id, email from app_public.user_emails ue join uid on (uid.id=ue.user_id) where user_id=uid.id),
     oid(id) as (select id from app_public.organizations where slug='marca'::citext)
insert into app_public.organization_invitations (email, code, organization_id)
   select eml.email as email, 'blahblah code' as code,  oid.id as organization_id
   from eml
   join oid on (true);

prepare happy_path_1 as
with
uid(id) as (select id from app_public.users where username='gd'),
oi(id,code) as (
   select oi.id,oi.code from app_public.organization_invitations oi
   join uid on (oi.user_id=uid.id))
select app_public.organization_for_invitation (oi.id, oi.code )
from oi;

prepare organization_is as select o.* from app_public.organizations o where slug='marca';

SET ROLE :DATABASE_VISITOR;

select results_eq('happy_path_1',
                  'organization_is',
                  'Should correctly match invite id and code with organization');



SELECT finish();
ROLLBACK;
