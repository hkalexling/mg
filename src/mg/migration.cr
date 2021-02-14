require "db"

module MG
  class Migration
    # Instantiates a `Migration` object to migrate a DB.
    #
    # - *tag*: See `Tags`.
    # - *version_table*: The name of the table to create to store the current
    #   schema version
    # - *version_column*: The column in *version_table* that stores the
    #   current schema version
    #
    # NOTE: In SQLite, *version_table* and *version_column* are ignored,
    #   because we can use the built-in *user_version* pragma to store
    #   the version.
    def initialize(@db : DB::Database, *, @tag : String? = nil,
                   @version_table = "mg_version",
                   @version_column = "mg_version",
                   @log : Log? = nil)
      unless versions.uniq(&.version).size == versions.size
        raise VersionError.new "Duplicate versions found"
      end
    end

    private def log
      @log || Log.for MG
    end

    # Lists the available versions for the current migration.
    def versions
      Base.versions.select do |v|
        if @tag.nil?
          v.tags.empty?
        else
          v.version == 0 || v.tags.includes? @tag
        end
      end
    end

    private def get_version(ver : Int32)
      versions.find { |v| v.version == ver }
    end

    private def next_version(ver : Int32)
      versions.find { |v| v.version > ver }
    end

    private def prev_version(ver : Int32)
      versions.reverse.find { |v| v.version < ver }
    end

    # :nodoc:
    macro use_version_table
      @db.transaction do |tran|
        conn = tran.connection
        conn.exec <<-SQL
        CREATE TABLE IF NOT EXISTS #{@version_table} (
          #{@version_column} INTEGER NOT NULL
        )
        SQL
        count = conn.query_one "SELECT COUNT(*) FROM #{@version_table}",
          as: Int64
        if count == 0
          conn.exec "INSERT INTO #{@version_table} VALUES (0)"
        end
      end
    end

    # Returns the current schema version.
    def user_version
      if sqlite?
        return @db.query_one "PRAGMA user_version", as: Int32
      end

      use_version_table
      query = <<-SQL
      SELECT #{@version_column}
      FROM #{@version_table}
      LIMIT 1
      SQL
      @db.query_one query, as: Int32
    end

    private def user_version=(ver : Int32)
      if sqlite?
        return @db.exec "PRAGMA user_version = #{ver}"
      end

      use_version_table
      @db.exec <<-SQL
      UPDATE #{@version_table}
      SET #{@version_column} = #{ver}
      SQL
    end

    # Returns true if the connection uses SQLite driver, false otherwise.
    private def sqlite? : Bool
      @db.driver.class.to_s == "SQLite3::Driver"
    end

    # Migrates to a specific version. When `to` is negative, migrates to the
    #   latest version available.
    def migrate(*, to : Int32 = -1)
      # When `to` is negative, use the latest version
      if to < 0
        if versions.empty?
          log.info { "No version found" }
          return
        end
        to = versions.last.version
      end

      unless get_version to
        raise VersionError.new "The target version #{to} does not exist in " \
                               "the versions list"
      end

      log.debug { "Current version: #{user_version}" }
      log.debug { "Target version: #{to}" }

      if to == user_version
        log.debug { "Nothing to be done" }
        return
      end

      is_up = to > user_version

      until user_version == to
        cur_ver = get_version user_version
        unless cur_ver
          raise VersionError.new "The current version #{user_version} does " \
                                 "not exist in the versions list"
        end
        target = if is_up
                   next_version(user_version).not_nil!
                 else
                   prev_version(user_version).not_nil!
                 end

        log.info { "Migrating to #{target.name} (#{target.version})" }

        @db.transaction do |tran|
          conn = tran.connection

          statements = is_up ? target.up_statements : cur_ver.down_statements
          statements.each do |query|
            conn.exec query
            log.debug { "Executing query:\n#{query}" }
          end
        end

        self.user_version = target.version
      end

      log.info { "Job done" }
    end
  end
end
