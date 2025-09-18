defmodule OjolMvp.ReviewsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OjolMvp.Reviews` context.
  """

  @doc """
  Generate a rating.
  """
  def rating_fixture(attrs \\ %{}) do
    {:ok, rating} =
      attrs
      |> Enum.into(%{
        comment: "some comment",
        rating: 42,
        reviewer_type: "some reviewer_type"
      })
      |> OjolMvp.Reviews.create_rating()

    rating
  end
end
