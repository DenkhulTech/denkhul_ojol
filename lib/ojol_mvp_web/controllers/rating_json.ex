defmodule OjolMvpWeb.RatingJSON do
  alias OjolMvp.Reviews.Rating

  @doc """
  Renders a list of ratings.
  """
  def index(%{ratings: ratings}) do
    %{data: for(rating <- ratings, do: data(rating))}
  end

  @doc """
  Renders a single rating.
  """
  def show(%{rating: rating}) do
    %{data: data(rating)}
  end

  defp data(%Rating{} = rating) do
    %{
      id: rating.id,
      rating: rating.rating,
      comment: rating.comment,
      reviewer_type: rating.reviewer_type
    }
  end
end
