defmodule OjolMvp.Reviews.Rating do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ratings" do
    field :rating, :integer
    field :comment, :string
    field :reviewer_type, :string
    field :order_id, :id
    field :reviewer_id, :id
    field :reviewee_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rating, attrs) do
    rating
    |> cast(attrs, [:rating, :comment, :reviewer_type])
    |> validate_required([:rating, :comment, :reviewer_type])
  end
end
