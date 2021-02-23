@[MG::Tags("db5")]
class UpdateLifecycle < MG::Base
  def up : String
    <<-SQL
    UPDATE lifecycle SET count = count + 1, up2 = "#{Time.utc.to_unix_ms}"
    SQL
  end

  def down : String
    <<-SQL
    UPDATE lifecycle SET count = count + 1, down2 = "#{Time.utc.to_unix_ms}"
    SQL
  end
end
