module MG
  struct Version
    getter version : Int32
    getter tags : Array(String)

    # :nodoc:
    getter mg : Base | String

    @up : String
    @down : String

    # :nodoc:
    def initialize(@mg, @version, @up, @down, @tags = [] of String)
    end

    # Returns a human-readable version name.
    def name : String
      @mg.to_s
    end

    private def split_statements(str : String) : Array(String)
      init = [[] of String] of Array(String)
      str.each_line
        .reduce init do |acc, line|
          line = line.rstrip
          acc[-1] << line
          if line.ends_with? ";"
            acc << [] of String
          end
          acc
        end
        .map(&.join "\n")
        .reject &.empty?
    end

    def up_statements : Array(String)
      split_statements @up
    end

    def down_statements : Array(String)
      split_statements @down
    end
  end
end
