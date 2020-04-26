# Organizations tables for postgraphile

Essentially a straight port from postgraphile starter sql

To use this, you need to have sqitch installed properly.  To run tests,
you need to have pg_prove installed properly.

# Install

To install, you have two choices.

First, go the usual sqitch route

```
sqitch deploy db:pg://dbuser@dbhost.name:dbport/mydb
```

Alternately, you can set some environment variables and use npm.

```
npm install
```

Accepting the default values, or

```
export PGUSER=someuser
export PGHOST=dbhostaddress
export PGPORT=5432
export PGDATABASE=mysqitchdb
npm install
```

# Tests

The tests use pg_prove, but at the moment they do absolulu nothing.

# Use as a dependency

To use as a dependency in a sqitch project, you have to use npm for
your sqitch project.  Use this package's scripts block as a guide, or
improve it and send me  pull request.  Then:

```
export PGUSER=someuser
export PGHOST=dbhostaddress
export PGPORT=5432
export PGDATABASE=mysqitchdb
npm install https://github.com/jmarca/postgraphile_user_system
```

That should do the trick.
