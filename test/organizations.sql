-- Test organizations
SET client_min_messages TO warning;
CREATE EXTENSION IF NOT EXISTS pgtap;
RESET client_min_messages;

BEGIN;
SELECT no_plan();
-- SELECT plan(1);

SET search_path TO app_public,public;

SELECT has_table('organizations');
SELECT has_pk( 'organizations' );

  SELECT has_column(        'organizations', 'id' );
SELECT col_type_is(       'organizations', 'id', 'uuid' );
SELECT col_not_null(      'organizations', 'id' );
SELECT col_has_default( 'organizations', 'id' );

  SELECT has_column(        'organizations', 'slug' );
SELECT col_type_is(       'organizations', 'slug', 'citext' );
SELECT col_not_null(      'organizations', 'slug' );
SELECT col_hasnt_default( 'organizations', 'slug' );
SELECT col_is_unique(     'organizations', 'slug' );

  SELECT has_column(        'organizations', 'name' );
SELECT col_type_is(       'organizations', 'name', 'text' );
SELECT col_not_null(      'organizations', 'name' );
SELECT col_hasnt_default( 'organizations', 'name' );

  SELECT has_column(        'organizations', 'created_at' );
SELECT col_type_is(       'organizations', 'created_at', 'timestamp with time zone' );
SELECT col_not_null(      'organizations', 'created_at' );
SELECT col_has_default( 'organizations', 'created_at' );



SELECT finish();
ROLLBACK;
