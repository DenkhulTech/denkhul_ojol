defmodule OjolMvp.Reviews do
  @moduledoc """
  The Reviews context.
  """

  import Ecto.Query, warn: false
  alias OjolMvp.Repo

  alias OjolMvp.Reviews.Rating

  @doc """
  Returns the list of ratings.
  """
  def list_ratings do
    Repo.all(Rating)
  end

  @doc """
  Gets a single rating.
  Returns nil if the Rating does not exist.
  """
  def get_rating!(id) do
    case Repo.get(Rating, id) do
      nil -> nil
      rating -> rating
    end
  end

  @doc """
  Creates a rating.
  """
  def create_rating(attrs) do
    %Rating{}
    |> Rating.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a rating.
  """
  def update_rating(%Rating{} = rating, attrs) do
    rating
    |> Rating.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a rating.
  """
  def delete_rating(%Rating{} = rating) do
    Repo.delete(rating)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking rating changes.
  """
  def change_rating(%Rating{} = rating, attrs \\ %{}) do
    Rating.changeset(rating, attrs)
  end
end
