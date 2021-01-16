class CreateUsers < MG::Base
  def up : String
    <<-SQL
    create table users (
      username text not null,
      password text not null,
      is_admin integer not null
    );
    create unique index un_idx on users (username);
    create unique index up_idx on users (password);
    SQL
  end

  def down : String
    <<-SQL
    drop table users;
    SQL
  end
end
