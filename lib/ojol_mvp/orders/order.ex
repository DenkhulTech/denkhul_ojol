defmodule OjolMvp.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field :pickup_address, :string
    field :pickup_lat, :decimal
    field :pickup_lng, :decimal
    field :destination_address, :string
    field :destination_lat, :decimal
    field :destination_lng, :decimal
    field :distance_km, :decimal
    field :price, :integer
    field :status, :string
    field :notes, :string
    field :customer_id, :id
    field :driver_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
 def changeset(order, attrs) do
  order
  |> cast(attrs, [:pickup_address, :pickup_lat, :pickup_lng, :destination_address,
                  :destination_lat, :destination_lng, :distance_km, :price, :status,
                  :notes, :customer_id, :driver_id])  # Add customer_id and driver_id here
  |> validate_required([:pickup_address, :pickup_lat, :pickup_lng, :destination_address,
                        :destination_lat, :destination_lng, :distance_km, :price, :status,
                        :notes])
end
end
