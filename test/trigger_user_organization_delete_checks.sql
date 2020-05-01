SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT pass('Test trigger_user_organization_delete_checks!');

-- test your function --


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
u(id) as (select id from app_public.users where username='jmarca')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, true, false
  from o
  join u on (true);

WITH
o(id) as (select id from app_public.organizations where slug='dolls'),
u(id) as (select id from app_public.users where username='gd')
INSERT INTO app_public.organization_memberships (organization_id, user_id, is_owner, is_billing_contact)
  select o.id, u.id, false, true
  from o
  join u on (true);

-- utility to snag token
create function app_public.get_delete_token() returns text as $$
  select delete_account_token from app_private.user_secrets where user_id = app_public.current_user_id();
$$ language sql stable security definer set search_path to pg_catalog, public, pg_temp;



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

-- baseline
SELECT results_eq('select slug from app_public.organizations order by slug',
       'VALUES (' || quote_literal('dolls') ||'::citext), (' || quote_literal('marca') ||'::citext)',
       'should see two organizations');

select results_eq('select username from app_public.organization_memberships om join app_public.users u on om.user_id=u.id join app_public.organizations o on (o.id=om.organization_id) where o.slug=' || quote_literal('marca') ||'::citext  order by username',
        'VALUES (' || quote_literal('gd') ||'::citext), (' || quote_literal('jmarca') ||'::citext)',
        'Should be able to view the current members of an organization');

-- delete own account

select app_public.request_account_deletion();

-- -- get the token that was generated
-- select delete_account_token
-- from update app_private.user_secrets
-- where user_id = app_public.current_user_id()
-- into v_token;

-- call the confirm delete function with bad token
select throws_ok('select app_public.confirm_account_deletion('||quote_literal('bob guy')||')',
       'DNIED',
       'The supplied token was incorrect - perhaps you''re logged in to the wrong account, or the token has expired?',
       'should not be able to delete self with bad token');


-- call the confirm delete function with correct token
select results_eq('select app_public.confirm_account_deletion(app_public.get_delete_token())',
        $$VALUES(true) $$,
        'should be able to delete self if not an org owner');


select is_empty('select slug from app_public.organizations order by slug',
        'should see no organizations');

select is_empty('select username from app_public.organization_memberships om join app_public.users u on om.user_id=u.id join app_public.organizations o on (o.id=om.organization_id) where o.slug=' || quote_literal('dolls') ||'::citext  order by username',
       'Should be not be able to see any members of organizations');

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


SET ROLE :DATABASE_VISITOR;

-- baseline
SELECT results_eq('select slug from app_public.organizations order by slug',
       'VALUES (' || quote_literal('dolls') ||'::citext), (' || quote_literal('marca') ||'::citext)',
       'should see two organizations');

select results_eq('select username from app_public.organization_memberships om join app_public.users u on om.user_id=u.id join app_public.organizations o on (o.id=om.organization_id) where o.slug=' || quote_literal('marca') ||'::citext  order by username',
        'VALUES (' || quote_literal('jmarca') ||'::citext)',
        'Should be able to view the current members of an organization');

-- delete own account

select app_public.request_account_deletion();

-- call the confirm delete function
select throws_ok('select app_public.confirm_account_deletion(app_public.get_delete_token())',
                  'OWNER',
                  'You cannot delete your account until you are not the owner of any organizations.',
        'should not be able to delete self if an org owner');


SELECT finish();
ROLLBACK;
