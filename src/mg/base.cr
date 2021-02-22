module MG
  # All user defined versions must inherite from this class, and implement
  #   the `up` and `down` methods.
  #
  # ```
  # class CreateUser < MG::Base
  #   def up : String
  #     <<-SQL
  #     CREATE TABLE users (
  #       username TEXT NOT NULL,
  #       password TEXT NOT NULL,
  #       email TEXT NOT NULL
  #     );
  #     CREATE UNIQUE INDEX user_idx ON users (username);
  #     SQL
  #   end
  #
  #   def down : String
  #     <<-SQL
  #     DROP TABLE users;
  #     SQL
  #   end
  # end
  # ```
  abstract class Base
    # :nodoc:
    abstract def up : String
    # :nodoc:
    abstract def down : String

    def after_up(db : DB::Connection); end

    def after_down(db : DB::Connection); end

    macro inherited
      def version : Int32
        ver = -1
        begin
          ver = __FILE__.match(/^.+\.([0-9]+)\.cr$/).not_nil![1].to_i
        rescue
          raise MG::FilenameError.new "The filename #{__FILE__} does not " \
              "contain a valid version number"
        end
        unless ver > 0
          raise MG::FilenameError.new "Version number must be non-negative, " \
            "but we found #{ver} in #{__FILE__}"
        end
        ver
      end
    end

    def to_s
      self.class.name
    end

    # Lists all versions available. The versions are sorted by version number.
    def self.versions : Array(Version)
      versions = [] of Version
      versions << Version.new "BaseVersion", 0, "", ""
      {% for sc in @type.subclasses %}
        mg = {{sc.id}}.new
        tags = [] of String
        {% if anno = sc.annotation(Tags) %}
          {% for tag in anno.args %}
            tags << {{tag}}
          {% end %}
        {% end %}
        versions << Version.new mg, mg.version, mg.up, mg.down, tags
      {% end %}
      versions.sort_by &.version
    end
  end
end
