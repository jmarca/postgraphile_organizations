-- Test organization_invitations
SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT has_table('organization_invitations');
SELECT has_pk( 'organization_invitations' );

  SELECT has_column(        'organization_invitations', 'id' );
SELECT col_type_is(       'organization_invitations', 'id', 'uuid' );
SELECT col_not_null(      'organization_invitations', 'id' );
SELECT col_has_default( 'organization_invitations', 'id' );

  SELECT has_column(        'organization_invitations', 'organization_id' );
SELECT col_type_is(       'organization_invitations', 'organization_id', 'uuid' );
SELECT col_not_null(      'organization_invitations', 'organization_id' );
SELECT col_hasnt_default( 'organization_invitations', 'organization_id' );

  SELECT has_column(        'organization_invitations', 'code' );
SELECT col_type_is(       'organization_invitations', 'code', 'text' );
SELECT col_is_null(      'organization_invitations', 'code' );
SELECT col_hasnt_default( 'organization_invitations', 'code' );

  SELECT has_column(        'organization_invitations', 'user_id' );
SELECT col_type_is(       'organization_invitations', 'user_id', 'uuid' );
SELECT col_is_null(      'organization_invitations', 'user_id' );
SELECT col_hasnt_default( 'organization_invitations', 'user_id' );

  SELECT has_column(        'organization_invitations', 'email' );
SELECT col_type_is(       'organization_invitations', 'email', 'citext' );
SELECT col_is_null(      'organization_invitations', 'email' );
SELECT col_hasnt_default( 'organization_invitations', 'email' );

SELECT col_is_unique( 'organization_invitations', ARRAY['organization_id', 'user_id'] );
SELECT col_is_unique( 'organization_invitations', ARRAY['organization_id', 'email'] );
SELECT col_is_pk(     'organization_invitations','id' );

SELECT col_has_check( 'organization_invitations', ARRAY['user_id', 'email'] );
SELECT col_has_check( 'organization_invitations', ARRAY['code', 'email'] );

SELECT table_privs_are( 'app_public', 'organization_invitations', :'DATABASE_VISITOR', ARRAY['SELECT']);

SELECT fk_ok( 'organization_invitations', 'organization_id', 'organizations', 'id' );
SELECT fk_ok( 'organization_invitations', 'user_id', 'users', 'id' );




SELECT finish();
ROLLBACK;
