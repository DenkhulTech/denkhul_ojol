defmodule OjolMvpWeb.RatingController do
  use OjolMvpWeb, :controller

  alias OjolMvp.Reviews
  alias OjolMvp.Reviews.Rating
  alias OjolMvp.Orders
  alias Guardian.Plug.EnsureAuthenticated
  alias Guardian.Plug.LoadResource

  action_fallback OjolMvpWeb.FallbackController

  # All rating actions require authentication
  plug EnsureAuthenticated
  plug LoadResource

  @doc """
  Create new rating - only participants of completed order can rate
  """
  def create(conn, %{"rating" => rating_params}) do
    current_user = Guardian.Plug.current_resource(conn)

    case validate_rating_params(rating_params) do
      :ok ->
        case authorize_rating_creation(current_user, rating_params) do
          :ok ->
            rating_params_with_rater = Map.put(rating_params, "rater_id", current_user.id)

            with {:ok, %Rating{} = rating} <- Reviews.create_rating(rating_params_with_rater) do
              # Load associations for complete response
              rating = get_rating_with_associations(rating.id)

              conn
              |> put_status(:created)
              |> put_resp_header("location", ~p"/api/ratings/#{rating.id}")
              |> json(%{
                data: format_rating_response(rating),
                message: "Rating created successfully"
              })
            end

          {:error, message} ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: message})
        end

      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end

  @doc """
  Show specific rating - only participants can view
  """
  def show(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(id) do
      {:ok, rating_id} ->
        case get_rating_with_associations(rating_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Rating not found"})

          rating ->
            if can_view_rating?(current_user, rating) do
              json(conn, %{data: format_rating_response(rating)})
            else
              conn
              |> put_status(:forbidden)
              |> json(%{error: "You don't have permission to view this rating"})
            end
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid rating ID"})
    end
  end

  @doc """
  Update rating - only the rater can update within time limit
  """
  def update(conn, %{"id" => id, "rating" => rating_params}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(id) do
      {:ok, rating_id} ->
        case get_rating_with_associations(rating_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Rating not found"})

          rating ->
            case authorize_rating_update(current_user, rating) do
              :ok ->
                case validate_update_params(rating_params) do
                  :ok ->
                    with {:ok, %Rating{} = updated_rating} <-
                           Reviews.update_rating(rating, rating_params) do
                      updated_rating = get_rating_with_associations(updated_rating.id)

                      json(conn, %{
                        data: format_rating_response(updated_rating),
                        message: "Rating updated successfully"
                      })
                    end

                  {:error, message} ->
                    conn
                    |> put_status(:bad_request)
                    |> json(%{error: message})
                end

              {:error, message} ->
                conn
                |> put_status(:forbidden)
                |> json(%{error: message})
            end
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid rating ID"})
    end
  end

  @doc """
  Delete rating - only the rater can delete within time limit
  """
  def delete(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(id) do
      {:ok, rating_id} ->
        case Reviews.get_rating!(rating_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Rating not found"})

          rating ->
            case authorize_rating_deletion(current_user, rating) do
              :ok ->
                with {:ok, %Rating{}} <- Reviews.delete_rating(rating) do
                  json(conn, %{message: "Rating deleted successfully"})
                end

              {:error, message} ->
                conn
                |> put_status(:forbidden)
                |> json(%{error: message})
            end
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid rating ID"})
    end
  end

  @doc """
  Get ratings created by current user
  """
  def my_ratings(conn, params) do
    current_user = Guardian.Plug.current_resource(conn)

    {page, limit} = parse_pagination_params(params)

    ratings = get_ratings_by_rater(current_user.id, page, limit)
    total_count = count_ratings_by_rater(current_user.id)

    json(conn, %{
      data: Enum.map(ratings, &format_rating_response/1),
      pagination: %{
        page: page,
        limit: limit,
        total_count: total_count,
        total_pages: ceil(total_count / limit)
      }
    })
  end

  @doc """
  Get ratings received by current user (as rated user)
  """
  def received_ratings(conn, params) do
    current_user = Guardian.Plug.current_resource(conn)

    {page, limit} = parse_pagination_params(params)

    ratings = get_ratings_for_user(current_user.id, page, limit)
    total_count = count_ratings_for_user(current_user.id)
    average_rating = get_average_rating_for_user(current_user.id)

    json(conn, %{
      data: Enum.map(ratings, &format_rating_response/1),
      stats: %{
        average_rating: average_rating,
        total_ratings: total_count
      },
      pagination: %{
        page: page,
        limit: limit,
        total_count: total_count,
        total_pages: ceil(total_count / limit)
      }
    })
  end

  @doc """
  Get ratings for a specific user (public endpoint for viewing driver/customer ratings)
  """
  def user_ratings(conn, %{"user_id" => user_id} = params) do
    case parse_integer(user_id) do
      {:ok, id} ->
        {page, limit} = parse_pagination_params(params)

        ratings = get_public_ratings_for_user(id, page, limit)
        total_count = count_ratings_for_user(id)
        average_rating = get_average_rating_for_user(id)

        json(conn, %{
          data: Enum.map(ratings, &format_public_rating_response/1),
          stats: %{
            average_rating: average_rating,
            total_ratings: total_count
          },
          pagination: %{
            page: page,
            limit: limit,
            total_count: total_count,
            total_pages: ceil(total_count / limit)
          }
        })

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid user ID"})
    end
  end

  # Private functions

  # Custom functions to replace non-existent Reviews functions

  defp get_rating_with_associations(rating_id) do
    case Reviews.get_rating!(rating_id) do
      nil -> nil
      rating -> OjolMvp.Repo.preload(rating, [:rater, :rated_user, :order])
    end
  end

  defp get_ratings_by_rater(rater_id, page, limit) do
    import Ecto.Query

    from(r in Rating,
      where: r.rater_id == ^rater_id,
      preload: [:rater, :rated_user, :order],
      order_by: [desc: r.inserted_at],
      limit: ^limit,
      offset: ^((page - 1) * limit)
    )
    |> OjolMvp.Repo.all()
  end

  defp count_ratings_by_rater(rater_id) do
    import Ecto.Query

    from(r in Rating,
      where: r.rater_id == ^rater_id,
      select: count(r.id)
    )
    |> OjolMvp.Repo.one()
  end

  defp get_ratings_for_user(user_id, page, limit) do
    import Ecto.Query

    from(r in Rating,
      where: r.rated_user_id == ^user_id,
      preload: [:rater, :rated_user, :order],
      order_by: [desc: r.inserted_at],
      limit: ^limit,
      offset: ^((page - 1) * limit)
    )
    |> OjolMvp.Repo.all()
  end

  defp count_ratings_for_user(user_id) do
    import Ecto.Query

    from(r in Rating,
      where: r.rated_user_id == ^user_id,
      select: count(r.id)
    )
    |> OjolMvp.Repo.one()
  end

  defp get_average_rating_for_user(user_id) do
    import Ecto.Query

    result =
      from(r in Rating,
        where: r.rated_user_id == ^user_id,
        select: avg(r.rating)
      )
      |> OjolMvp.Repo.one()

    case result do
      nil -> 0.0
      avg when is_number(avg) -> Float.round(avg, 2)
      _ -> 0.0
    end
  end

  defp get_public_ratings_for_user(user_id, page, limit) do
    import Ecto.Query

    from(r in Rating,
      where: r.rated_user_id == ^user_id,
      preload: [:rater],
      order_by: [desc: r.inserted_at],
      limit: ^limit,
      offset: ^((page - 1) * limit)
    )
    |> OjolMvp.Repo.all()
  end

  defp rating_exists?(order_id, rater_id, rated_user_id) do
    import Ecto.Query

    query =
      from(r in Rating,
        where:
          r.order_id == ^order_id and
            r.rater_id == ^rater_id and
            r.rated_user_id == ^rated_user_id
      )

    OjolMvp.Repo.exists?(query)
  end

  defp validate_rating_params(params) do
    required_fields = ["order_id", "rated_user_id", "rating", "comment"]

    cond do
      !is_map(params) ->
        {:error, "Invalid rating data format"}

      Enum.any?(required_fields, &(is_nil(params[&1]) or params[&1] == "")) ->
        {:error, "Missing required fields: #{Enum.join(required_fields, ", ")}"}

      !is_integer(params["rating"]) or params["rating"] < 1 or params["rating"] > 5 ->
        {:error, "Rating must be an integer between 1 and 5"}

      String.length(params["comment"]) > 1000 ->
        {:error, "Comment must not exceed 1000 characters"}

      String.length(params["comment"]) < 5 ->
        {:error, "Comment must be at least 5 characters long"}

      true ->
        :ok
    end
  end

  defp validate_update_params(params) do
    cond do
      !is_map(params) ->
        {:error, "Invalid rating data format"}

      params["rating"] &&
          (!is_integer(params["rating"]) or params["rating"] < 1 or params["rating"] > 5) ->
        {:error, "Rating must be an integer between 1 and 5"}

      params["comment"] && String.length(params["comment"]) > 1000 ->
        {:error, "Comment must not exceed 1000 characters"}

      params["comment"] && String.length(params["comment"]) < 5 ->
        {:error, "Comment must be at least 5 characters long"}

      true ->
        :ok
    end
  end

  defp authorize_rating_creation(current_user, rating_params) do
    order_id = rating_params["order_id"]
    rated_user_id = rating_params["rated_user_id"]

    case Orders.get_order!(order_id) do
      nil ->
        {:error, "Order not found"}

      order ->
        cond do
          order.status != "completed" ->
            {:error, "Can only rate completed orders"}

          current_user.id != order.customer_id and current_user.id != order.driver_id ->
            {:error, "You can only rate orders you participated in"}

          rated_user_id != order.customer_id and rated_user_id != order.driver_id ->
            {:error, "You can only rate participants of this order"}

          current_user.id == rated_user_id ->
            {:error, "You cannot rate yourself"}

          rating_exists?(order_id, current_user.id, rated_user_id) ->
            {:error, "You have already rated this user for this order"}

          true ->
            :ok
        end
    end
  end

  defp authorize_rating_update(current_user, rating) do
    cond do
      rating.rater_id != current_user.id ->
        {:error, "You can only update your own ratings"}

      rating_too_old?(rating) ->
        {:error, "Rating can only be updated within 24 hours of creation"}

      true ->
        :ok
    end
  end

  defp authorize_rating_deletion(current_user, rating) do
    cond do
      rating.rater_id != current_user.id ->
        {:error, "You can only delete your own ratings"}

      rating_too_old?(rating) ->
        {:error, "Rating can only be deleted within 1 hour of creation"}

      true ->
        :ok
    end
  end

  defp can_view_rating?(current_user, rating) do
    # User can view if they are the rater or the rated user
    current_user.id == rating.rater_id or current_user.id == rating.rated_user_id
  end

  defp rating_too_old?(rating, hours_limit \\ 24) do
    DateTime.diff(DateTime.utc_now(), rating.inserted_at, :hour) > hours_limit
  end

  defp format_rating_response(rating) do
    %{
      id: rating.id,
      rating: rating.rating,
      comment: rating.comment,
      order_id: rating.order_id,
      rater: %{
        id: rating.rater.id,
        name: rating.rater.name,
        role: rating.rater.role
      },
      rated_user: %{
        id: rating.rated_user.id,
        name: rating.rated_user.name,
        role: rating.rated_user.role
      },
      inserted_at: rating.inserted_at,
      updated_at: rating.updated_at
    }
  end

  defp format_public_rating_response(rating) do
    %{
      id: rating.id,
      rating: rating.rating,
      comment: rating.comment,
      rater_name: mask_name(rating.rater.name),
      inserted_at: rating.inserted_at
    }
  end

  defp mask_name(name) do
    # Mask name for privacy (e.g., "John Doe" -> "J*** D***")
    parts = String.split(name, " ")

    Enum.map(parts, fn part ->
      if String.length(part) > 1 do
        String.first(part) <> String.duplicate("*", String.length(part) - 1)
      else
        part
      end
    end)
    |> Enum.join(" ")
  end

  defp parse_pagination_params(params) do
    page = params["page"] |> parse_positive_integer(1)
    # Max 100 items per page
    limit = params["limit"] |> parse_positive_integer(10) |> min(100)
    {page, limit}
  end

  defp parse_positive_integer(nil, default), do: default
  defp parse_positive_integer(value, _default) when is_integer(value) and value > 0, do: value

  defp parse_positive_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} when int > 0 -> int
      _ -> default
    end
  end

  defp parse_positive_integer(_, default), do: default

  defp parse_integer(value) when is_integer(value), do: {:ok, value}

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  defp parse_integer(_), do: :error
end
