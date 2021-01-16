@[MG::Tags("db2", "db3")]
class CreateQueue < MG::Base
  def up : String
    <<-SQL
    CREATE TABLE queue (
      id TEXT NOT NULL,
      time INTEGER NOT NULL,
      state INTEGER NOT NULL
    )
    SQL
  end

  def down : String
    <<-SQL
    DROP TABLE queue
    SQL
  end
end
