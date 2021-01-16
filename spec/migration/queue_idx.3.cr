@[MG::Tags("db2")]
class QueueIndex < MG::Base
  def up : String
    <<-SQL
    CREATE UNIQUE INDEX qid_idx ON queue (id)
    SQL
  end

  def down : String
    <<-SQL
    DROP INDEX qid_idx
    SQL
  end
end
