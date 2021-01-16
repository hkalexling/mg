module MG
  class FilenameError < Exception
  end

  class VersionError < Exception
  end

  # You can tag a subclass of `Base` using this annotatation.
  #
  # For example, the following version will only be visible in `Migration`s
  #   instantiated with the tag "prod" or "dev1".
  # ```
  # @[MG::Tags("prod", "dev1")]
  # class MyVersion < MG::Base
  #   # ...
  # end
  #
  # DB.open "sqlite://file.db" do |db|
  #   mg = MG::Migration.new db
  #   mg.versions # Does not include `MyVersion` we defined above
  # end
  #
  # DB.open "sqlite://file.db" do |db|
  #   mg = MG::Migration.new db, tag: "prod"
  #   mg.versions # This includes `MyVersion`
  # end
  #
  # DB.open "sqlite://file.db" do |db|
  #   mg = MG::Migration.new db, tag: "dev1"
  #   mg.versions # This includes `MyVersion`
  # end
  # ```
  annotation Tags
  end
end
