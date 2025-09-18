defmodule OjolMvp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :phone, :string
      add :type, :string
      add :latitude, :decimal
      add :longitude, :decimal
      add :is_available, :boolean, default: false, null: false
      add :average_rating, :decimal
      add :total_ratings, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
