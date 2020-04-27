-- Test organization_memberships
SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT has_table('organization_memberships');
SELECT has_pk( 'organization_memberships' );

  SELECT has_column(        'organization_memberships', 'id' );
SELECT col_type_is(       'organization_memberships', 'id', 'uuid' );
SELECT col_not_null(      'organization_memberships', 'id' );
SELECT col_has_default( 'organization_memberships', 'id' );

  SELECT has_column(        'organization_memberships', 'organization_id' );
SELECT col_type_is(       'organization_memberships', 'organization_id', 'uuid' );
SELECT col_not_null(      'organization_memberships', 'organization_id' );
SELECT col_hasnt_default( 'organization_memberships', 'organization_id' );

  SELECT has_column(      'organization_memberships', 'user_id' );
SELECT col_type_is(       'organization_memberships', 'user_id', 'uuid' );
SELECT col_not_null(      'organization_memberships', 'user_id' );
SELECT col_hasnt_default( 'organization_memberships', 'user_id' );

  SELECT has_column(        'organization_memberships', 'is_owner' );
SELECT col_type_is(       'organization_memberships', 'is_owner', 'boolean' );
SELECT col_not_null(      'organization_memberships', 'is_owner' );
SELECT col_has_default( 'organization_memberships', 'is_owner' );

  SELECT has_column(        'organization_memberships', 'is_billing_contact' );
SELECT col_type_is(       'organization_memberships', 'is_billing_contact', 'boolean' );
SELECT col_not_null(      'organization_memberships', 'is_billing_contact' );
SELECT col_has_default( 'organization_memberships', 'is_billing_contact' );

  SELECT has_column(        'organization_memberships', 'created_at' );
SELECT col_type_is(       'organization_memberships', 'created_at', 'timestamp with time zone' );
SELECT col_not_null(      'organization_memberships', 'created_at' );
SELECT col_has_default( 'organization_memberships', 'created_at' );

SELECT col_is_unique( 'organization_memberships', ARRAY['organization_id', 'user_id'] );
SELECT col_is_pk(     'organization_memberships','id' );

SELECT fk_ok( 'organization_memberships', 'organization_id', 'organizations', 'id' );
SELECT fk_ok( 'organization_memberships', 'user_id', 'users', 'id' );




SELECT finish();
ROLLBACK;
