defmodule OjolMvp.Repo.Migrations.CreateRatings do
  use Ecto.Migration

  def change do
    create table(:ratings) do
      add :rating, :integer
      add :comment, :text
      add :reviewer_type, :string
      add :order_id, references(:orders, on_delete: :nothing)
      add :reviewer_id, references(:users, on_delete: :nothing)
      add :reviewee_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:ratings, [:order_id])
    create index(:ratings, [:reviewer_id])
    create index(:ratings, [:reviewee_id])
  end
end
