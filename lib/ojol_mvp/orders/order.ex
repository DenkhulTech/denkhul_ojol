defmodule OjolMvp.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias OjolMvp.Accounts.User
  alias OjolMvp.Reviews.Rating

  schema "orders" do
    field :pickup_address, :string
    field :pickup_lat, :decimal
    field :pickup_lng, :decimal
    field :destination_address, :string
    field :destination_lat, :decimal
    field :destination_lng, :decimal
    field :distance_km, :decimal
    field :price, :integer
    field :status, :string, default: "pending"
    field :notes, :string

    # Associations
    belongs_to :customer, User, foreign_key: :customer_id
    belongs_to :driver, User, foreign_key: :driver_id
    has_many :ratings, Rating

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :pickup_address,
      :pickup_lat,
      :pickup_lng,
      :destination_address,
      :destination_lat,
      :destination_lng,
      :distance_km,
      :price,
      :status,
      :notes,
      :customer_id,
      :driver_id
    ])
    |> validate_required([
      :pickup_address,
      :pickup_lat,
      :pickup_lng,
      :destination_address,
      :destination_lat,
      :destination_lng,
      :price,
      :status
    ])
    |> validate_length(:pickup_address, min: 5, max: 255)
    |> validate_length(:destination_address, min: 5, max: 255)
    |> validate_length(:notes, max: 500)
    |> validate_number(:pickup_lat, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:pickup_lng, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> validate_number(:destination_lat, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:destination_lng,
      greater_than_or_equal_to: -180,
      less_than_or_equal_to: 180
    )
    |> validate_number(:distance_km, greater_than: 0, less_than: 1000)
    |> validate_number(:price, greater_than: 0, less_than: 10_000_000)
    |> validate_inclusion(:status, [
      "pending",
      "accepted",
      "in_progress",
      "completed",
      "cancelled"
    ])
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:driver_id)
    |> validate_coordinates_different()
  end

  defp validate_coordinates_different(changeset) do
    pickup_lat = get_change(changeset, :pickup_lat)
    pickup_lng = get_change(changeset, :pickup_lng)
    dest_lat = get_change(changeset, :destination_lat)
    dest_lng = get_change(changeset, :destination_lng)

    if pickup_lat && pickup_lng && dest_lat && dest_lng do
      if Decimal.equal?(pickup_lat, dest_lat) && Decimal.equal?(pickup_lng, dest_lng) do
        add_error(changeset, :destination_address, "must be different from pickup location")
      else
        changeset
      end
    else
      changeset
    end
  end
end
