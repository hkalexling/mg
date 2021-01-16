class CreateIDs < MG::Base
  def up : String
    <<-SQL
    CREATE TABLE ids (
      id TEXT NOT NULL,
      path TEXT NOT NULL
    );
    CREATE UNIQUE INDEX iid_idx ON ids (id);
    CREATE UNIQUE INDEX ip_idx ON ids (path);
    SQL
  end

  def down : String
    "DROP TABLE ids"
  end
end
