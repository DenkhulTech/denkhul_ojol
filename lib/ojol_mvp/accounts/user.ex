defmodule OjolMvp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :phone, :string
    field :type, :string
    field :latitude, :decimal
    field :longitude, :decimal
    field :is_available, :boolean, default: false
    field :average_rating, :decimal
    field :total_ratings, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :phone, :type, :latitude, :longitude, :is_available, :average_rating, :total_ratings])
    |> validate_required([:name, :phone, :type, :latitude, :longitude, :is_available, :average_rating, :total_ratings])
  end
end
