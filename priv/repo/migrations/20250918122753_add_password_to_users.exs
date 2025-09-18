defmodule OjolMvp.Repo.Migrations.AddPasswordToUsers do
  use Ecto.Migration

  def change do
    # Remove duplicates first
    execute "DELETE FROM users WHERE id NOT IN (SELECT MIN(id) FROM users GROUP BY phone)"

    alter table(:users) do
      add :password_hash, :string, null: true
    end

    # Set default password for existing users
    execute "UPDATE users SET password_hash = '$argon2id$v=19$m=65536,t=1,p=1$defaulthash' WHERE password_hash IS NULL"

    # Make field required
    alter table(:users) do
      modify :password_hash, :string, null: false
    end

    # Add unique index
    create unique_index(:users, [:phone])
  end
end
