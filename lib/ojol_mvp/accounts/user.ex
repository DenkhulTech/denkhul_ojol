defmodule OjolMvp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias OjolMvp.Orders.Order
  alias OjolMvp.Reviews.Rating

  schema "users" do
    field :name, :string
    field :phone, :string
    field :type, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :latitude, :decimal
    field :longitude, :decimal
    field :is_available, :boolean, default: false
    field :average_rating, :decimal
    field :total_ratings, :integer

    # Associations
    has_many :customer_orders, Order, foreign_key: :customer_id
    has_many :driver_orders, Order, foreign_key: :driver_id
    has_many :given_ratings, Rating, foreign_key: :reviewer_id
    has_many :received_ratings, Rating, foreign_key: :reviewee_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :name,
      :phone,
      :type,
      :password,
      :latitude,
      :longitude,
      :is_available,
      :average_rating,
      :total_ratings
    ])
    |> validate_required([:name, :phone, :type])
    |> validate_length(:name, min: 2, max: 50)
    |> validate_length(:password, min: 6, max: 128)
    |> validate_format(:phone, ~r/^\+62[0-9]{9,12}$/)
    |> validate_inclusion(:type, ["customer", "driver"])
    |> unique_constraint(:phone)
    |> put_default_values()
    |> put_password_hash()
  end

  defp put_default_values(changeset) do
    changeset
    |> put_change(:average_rating, Decimal.new("0.0"))
    |> put_change(:total_ratings, 0)
    |> put_change(:is_available, true)
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, password_hash: Argon2.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
