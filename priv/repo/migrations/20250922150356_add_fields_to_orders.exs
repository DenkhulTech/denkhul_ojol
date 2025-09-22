# priv/repo/migrations/add_fields_to_orders.exs
defmodule OjolMvp.Repo.Migrations.AddFieldsToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :estimated_duration, :integer
      add :total_fare, :integer
      add :route_geometry, :map
    end
  end
end
