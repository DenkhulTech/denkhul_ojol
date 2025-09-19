defmodule OjolMvp.Reviews.Rating do
  use Ecto.Schema
  import Ecto.Changeset

  alias OjolMvp.Accounts.User
  alias OjolMvp.Orders.Order

  schema "ratings" do
    field :rating, :integer
    field :comment, :string
    field :reviewer_type, :string

    # Fixed field names to match controller expectations
    belongs_to :reviewer, User, foreign_key: :reviewer_id
    belongs_to :reviewee, User, foreign_key: :reviewee_id
    belongs_to :order, Order

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rating, attrs) do
    rating
    |> cast(attrs, [:rating, :comment, :reviewer_type, :reviewer_id, :reviewee_id, :order_id])
    |> validate_required([
      :rating,
      :comment,
      :reviewer_type,
      :reviewer_id,
      :reviewee_id,
      :order_id
    ])
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_length(:comment, min: 5, max: 1000)
    |> validate_inclusion(:reviewer_type, ["customer", "driver"])
    |> foreign_key_constraint(:reviewer_id)
    |> foreign_key_constraint(:reviewee_id)
    |> foreign_key_constraint(:order_id)
    |> validate_different_users()
    |> unique_constraint([:order_id, :reviewer_id, :reviewee_id],
      name: :ratings_order_reviewer_reviewee_index,
      message: "You have already rated this user for this order"
    )
  end

  defp validate_different_users(changeset) do
    reviewer_id = get_change(changeset, :reviewer_id)
    reviewee_id = get_change(changeset, :reviewee_id)

    if reviewer_id && reviewee_id && reviewer_id == reviewee_id do
      add_error(changeset, :reviewee_id, "cannot rate yourself")
    else
      changeset
    end
  end
end
