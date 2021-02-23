# MG

A minimal database migration tool for Crystal.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
 mg:
   github: hkalexling/mg
```

2. Run `shards install`

## Usage

First define some database versions by inheriting from `MG::Base`. Here are two examples:

```crystal
# migration/users.1.cr
class CreateUser < MG::Base
  def up : String
    <<-SQL
    CREATE TABLE users (
     username TEXT NOT NULL,
     password TEXT NOT NULL,
     email TEXT NOT NULL
    );
    SQL
  end

  def down : String
    <<-SQL
    DROP TABLE users;
    SQL
  end

  # Optional lifecycle method to be executed after the `up` query.
  def after_up
    puts "Table users created"
  end

  # Optional lifecycle method to be executed after the `down` query.
  def after_down
    puts "Table users dropped"
  end
end
```

```crystal
# migration/users_index.2.cr
class UserIndex < MG::Base
  def up : String
    <<-SQL
    CREATE UNIQUE INDEX username_idx ON users (username);
    CREATE UNIQUE INDEX email_idx ON users (email);
    SQL
  end

  def down : String
    <<-SQL
    DROP INDEX username_idx;
    DROP INDEX email_idx;
    SQL
  end
end
```

Note that the migration files must be named as `[filename].[non-negative-version-number].cr`.

Now require the relevant files and the migrations in your application code, and start the migration.

```crystal
require "mg"
require "sqlite3"
require "./migration/*"

Log.setup "mg", :debug
DB.open "sqlite3://file.db" do |db|
  mg = MG::Migration.new db

  # Migrates to the latest version (in our case, 2)
  mg.migrate

  # Migrates to a specific version
  mg.migrate to: 1

  # Migrates down to version 0
  mg.migrate to: 0

  # Returns the current version
  puts mg.user_version # 0
end
```

## Contributors

- [Alex Ling](https://github.com/hkalexling) - creator and maintainer
