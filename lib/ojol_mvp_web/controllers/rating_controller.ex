defmodule OjolMvpWeb.RatingController do
  use OjolMvpWeb, :controller

  alias OjolMvp.Reviews
  alias OjolMvp.Reviews.Rating

  action_fallback OjolMvpWeb.FallbackController

  def index(conn, _params) do
    ratings = Reviews.list_ratings()
    render(conn, :index, ratings: ratings)
  end

  def create(conn, %{"rating" => rating_params}) do
    with {:ok, %Rating{} = rating} <- Reviews.create_rating(rating_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/ratings/#{rating}")
      |> render(:show, rating: rating)
    end
  end

  def show(conn, %{"id" => id}) do
    rating = Reviews.get_rating!(id)
    render(conn, :show, rating: rating)
  end

  def update(conn, %{"id" => id, "rating" => rating_params}) do
    rating = Reviews.get_rating!(id)

    with {:ok, %Rating{} = rating} <- Reviews.update_rating(rating, rating_params) do
      render(conn, :show, rating: rating)
    end
  end

  def delete(conn, %{"id" => id}) do
    rating = Reviews.get_rating!(id)

    with {:ok, %Rating{}} <- Reviews.delete_rating(rating) do
      send_resp(conn, :no_content, "")
    end
  end
end
