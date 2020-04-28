-- Deploy postgraphile_organizations:organizations_current_user_is_owner to pg
-- requires: postgraphile_user_system:users
-- requires: postgraphile_user_system:current_user_id
-- requires: organizations

BEGIN;

SET SEARCH_PATH TO app_public,public;
CREATE OR REPLACE FUNCTION organizations_current_user_is_owner (
  org app_public.organizations) RETURNS boolean AS
$$
  select exists(
    select 1
    from app_public.organization_memberships
    where organization_id = org.id
    and user_id = app_public.current_user_id()
    and is_owner is true
  );
$$ language sql stable;

COMMENT ON FUNCTION organizations_current_user_is_owner (organizations) is
  E'Given an organizations row, check if the current user is the owner';


COMMIT;
