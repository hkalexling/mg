require "./spec_helper"
require "sqlite3"

Spec.after_suite do
  %w(./spec/db1.db ./spec/db2.db ./spec/db3.db ./spec/db4.db)
    .each do |path|
      File.delete path
    end
end

describe MG do
  describe MG::Base do
    it "loads all versions" do
      MG::Base.versions.map(&.version).should eq [0, 1, 1, 1, 2, 3]
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
  end
end
