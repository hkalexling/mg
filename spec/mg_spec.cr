require "./spec_helper"
require "sqlite3"

Spec.after_suite do
  %w(./spec/db1.db ./spec/db2.db ./spec/db3.db ./spec/db4.db ./spec/db5.db)
    .each do |path|
      File.delete path
    end
end

describe MG do
  describe MG::Base do
    it "loads all versions" do
      MG::Base.versions.map(&.version).should eq [0, 1, 1, 1, 1, 2, 2, 3]
    end
  end

  describe MG::Migration do
    it "handles tags correctly" do
      DB.open "sqlite3://./spec/db1.db" do |db|
        mg = MG::Migration.new db
        mg.versions.map(&.version).should eq [0, 1, 2]
      end
      DB.open "sqlite3://./spec/db2.db" do |db|
        mg = MG::Migration.new db, tag: "db2"
        mg.versions.map(&.version).should eq [0, 1, 3]
      end
      DB.open "sqlite3://./spec/db3.db" do |db|
        mg = MG::Migration.new db, tag: "db3"
        mg.versions.map(&.version).should eq [0, 1]
      end
    end

    it "migrates to the latest version" do
      DB.open "sqlite3://./spec/db1.db" do |db|
        mg = MG::Migration.new db
        mg.migrate
        mg.user_version.should eq 2
      end
      DB.open "sqlite3://./spec/db2.db" do |db|
        mg = MG::Migration.new db, tag: "db2"
        mg.migrate
        mg.user_version.should eq 3
      end
      DB.open "sqlite3://./spec/db3.db" do |db|
        mg = MG::Migration.new db, tag: "db3"
        mg.migrate
        mg.user_version.should eq 1
      end
    end

    it "migrates to version 0" do
      DB.open "sqlite3://./spec/db1.db" do |db|
        mg = MG::Migration.new db
        mg.migrate to: 0
        mg.user_version.should eq 0
      end
      DB.open "sqlite3://./spec/db2.db" do |db|
        mg = MG::Migration.new db, tag: "db2"
        mg.migrate to: 0
        mg.user_version.should eq 0
      end
      DB.open "sqlite3://./spec/db3.db" do |db|
        mg = MG::Migration.new db, tag: "db3"
        mg.migrate to: 0
        mg.user_version.should eq 0
      end
    end

    it "raises on syntax error" do
      DB.open "sqlite3://./spec/db4.db" do |db|
        mg = MG::Migration.new db, tag: "error"
        expect_raises SQLite3::Exception, /syntax error/ do
          mg.migrate
        end
      end
    end

    it "rolls back on error" do
      DB.open "sqlite3://./spec/db4.db" do |db|
        mg = MG::Migration.new db, tag: "error"
        mg.user_version.should eq 0
        expect_raises SQLite3::Exception, /no such table/ do
          db.exec "select * from errors"
        end
      end
    end

    it "handles lifecycle hooks correctly" do
      DB.open "sqlite3://./spec/db5.db" do |db|
        mg = MG::Migration.new db, tag: "db5"

        # Test migrate up
        mg.migrate
        mg.user_version.should eq 2

        lc = db.query_one(
          "select count, up, up2, down, down2, after_up, after_down from lifecycle",
          as: {
            count:      Int64,
            up:         Int64,
            up2:        Int64,
            down:       Nil,
            down2:      Nil,
            after_up:   Int64,
            after_down: Nil,
          }
        )

        count = lc[:count]
        up_time = Time.unix_ms(lc[:up])
        up_time2 = Time.unix_ms(lc[:up2])
        after_up_time = Time.unix_ms(lc[:after_up])

        # Count no more than: up + after_up
        count.should eq 2

        # Test the execution order.
        # We have only the first migration with a lifecyle.
        # Migration starts from the old to the recent.
        up_time.should be < after_up_time
        up_time2.should be > after_up_time

        # Test migrate down
        mg.migrate to: 0
        mg.user_version.should eq 0

        lc = db.query_one(
          "select count, up, up2, down, down2, after_up, after_down from lifecycle",
          as: {
            count:      Int64,
            up:         Int64,
            up2:        Int64,
            down:       Int64,
            down2:      Int64,
            after_up:   Int64,
            after_down: Int64,
          }
        )

        prev_count = count
        prev_up_time = up_time
        prev_up_time2 = up_time2
        prev_after_up_time = after_up_time

        count = lc[:count]
        up_time = Time.unix_ms(lc[:up])
        up_time2 = Time.unix_ms(lc[:up2])
        after_up_time = Time.unix_ms(lc[:after_up])
        down_time = Time.unix_ms(lc[:down])
        down_time2 = Time.unix_ms(lc[:down2])
        after_down_time = Time.unix_ms(lc[:after_down])

        # Count no more than: down + down + after_down
        count.should eq (prev_count + 3)

        # Test the execution order
        # We have only the first migration with a lifecyle
        up_time.should eq prev_up_time
        up_time2.should eq prev_up_time2
        after_up_time.should eq prev_after_up_time

        # Migration starts from the recent to the old.
        # down_time2 > (down_time > after_down_time)
        #
        # So, first the migration lifecycle.2
        # Then the migration lifecycle.1
        # down2 before down
        # down2 before after_down
        # down before after_down
        down_time2.should be < down_time
        down_time2.should be < after_down_time
        down_time.should be < after_down_time
      end
    end
  end
end
