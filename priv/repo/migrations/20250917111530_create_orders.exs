defmodule OjolMvp.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :pickup_address, :string
      add :pickup_lat, :decimal
      add :pickup_lng, :decimal
      add :destination_address, :string
      add :destination_lat, :decimal
      add :destination_lng, :decimal
      add :distance_km, :decimal
      add :price, :integer
      add :status, :string
      add :notes, :text
      add :customer_id, references(:users, on_delete: :nothing)
      add :driver_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:customer_id])
    create index(:orders, [:driver_id])
  end
end
