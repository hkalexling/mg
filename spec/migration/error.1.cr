@[MG::Tags("error")]
class Error < MG::Base
  def up : String
    <<-SQL
    CREATE TABLE errors (
      msg TEXT NOT NULL
    );
    Heyo :)
    SQL
  end

  def down : String
    ""
  end
end
