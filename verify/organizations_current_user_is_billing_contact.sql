-- Verify postgraphile_organizations:organizations_current_user_is_billing_contact on pg

BEGIN;

SET SEARCH_PATH TO app_public,public;
SELECT pg_catalog.has_function_privilege('organizations_current_user_is_billing_contact(organizations)','execute');

ROLLBACK;
