@[MG::Tags("db5")]
class CreateLifecycle < MG::Base
  def up : String
    <<-SQL
    CREATE TABLE lifecycle (
      up INTEGER,
      up2 INTEGER,
      down INTEGER,
      down2 INTEGER,
      after_up INTEGER,
      after_down INTEGER,
      count INTEGER DEFAULT 0
    );
    INSERT INTO lifecycle (up) VALUES ("#{Time.utc.to_unix_ms}");
    SQL
  end

  def down : String
    <<-SQL
    UPDATE lifecycle SET count = count + 1, down = "#{Time.utc.to_unix_ms}"
    SQL
  end

  def after_up(conn : DB::Connection)
    # The count is in milliseconds (unix_ms) but Crystal executes in nanoseconds.
    # So we extend the execution by one millisecond to compare times (in milliseconds) in tests.
    sleep 1.millisecond
    conn.exec %(UPDATE lifecycle SET count = count + 1, after_up = "#{Time.utc.to_unix_ms}")
  end

  def after_down(conn : DB::Connection)
    # The count is in milliseconds (unix_ms) but Crystal executes in nanoseconds.
    # So we extend the execution by one millisecond to compare times (in milliseconds) in tests.
    sleep 1.millisecond
    conn.exec %(UPDATE lifecycle SET count = count + 1, after_down = "#{Time.utc.to_unix_ms}")
  end
end
