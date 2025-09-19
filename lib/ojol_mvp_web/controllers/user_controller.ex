defmodule OjolMvpWeb.UserController do
  use OjolMvpWeb, :controller

  alias OjolMvp.Accounts.User
  alias Guardian.Plug.EnsureAuthenticated
  alias Guardian.Plug.LoadResource

  action_fallback OjolMvpWeb.FallbackController

  # Ensure authentication for protected actions
  plug EnsureAuthenticated when action in [:show, :update, :delete, :update_location, :profile]
  plug LoadResource when action in [:show, :update, :delete, :update_location, :profile]

  # Rate limiting untuk prevent spam registrasi
  plug :rate_limit_create when action in [:create]

  @doc """
  Create new user (registration) - public endpoint
  """
  def create(conn, %{"user" => user_params}) do
    # Validate required fields
    case validate_create_params(user_params) do
      :ok ->
        with {:ok, %User{} = user} <- OjolMvp.Accounts.create_user(user_params) do
          # Exclude sensitive fields
          safe_user = Map.take(user, [:id, :name, :phone, :type, :inserted_at])

          conn
          |> put_status(:created)
          |> put_resp_header("location", ~p"/api/users/#{user.id}")
          |> json(%{data: safe_user, message: "User created successfully"})
        end

      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end

  @doc """
  Get current user profile - no ID needed
  """
  def profile(conn, _params) do
    current_user = Guardian.Plug.current_resource(conn)

    # Exclude sensitive fields
    safe_user =
      Map.take(current_user, [
        :id,
        :name,
        :phone,
        :type,
        :latitude,
        :longitude,
        :is_available,
        :average_rating,
        :total_ratings,
        :inserted_at,
        :updated_at
      ])

    json(conn, %{data: safe_user})
  end

  @doc """
  Show user by ID - only own data allowed
  """
  def show(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(id) do
      {:ok, user_id} ->
        if current_user.id == user_id do
          safe_user =
            Map.take(current_user, [
              :id,
              :name,
              :phone,
              :type,
              :latitude,
              :longitude,
              :is_available,
              :average_rating,
              :total_ratings,
              :inserted_at,
              :updated_at
            ])

          json(conn, %{data: safe_user})
        else
          unauthorized_response(conn)
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid user ID"})
    end
  end

  @doc """
  Update user - only own data allowed
  """
  def update(conn, %{"id" => id, "user" => user_params}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(id) do
      {:ok, user_id} ->
        if current_user.id == user_id do
          # Validate and sanitize update params
          case validate_update_params(user_params) do
            :ok ->
              with {:ok, %User{} = user} <-
                     OjolMvp.Accounts.update_user(current_user, user_params) do
                safe_user =
                  Map.take(user, [
                    :id,
                    :name,
                    :phone,
                    :type,
                    :latitude,
                    :longitude,
                    :is_available,
                    :average_rating,
                    :total_ratings,
                    :updated_at
                  ])

                json(conn, %{data: safe_user, message: "User updated successfully"})
              end

            {:error, message} ->
              conn
              |> put_status(:bad_request)
              |> json(%{error: message})
          end
        else
          unauthorized_response(conn)
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid user ID"})
    end
  end

  @doc """
  Delete user - only own account allowed
  """
  def delete(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(id) do
      {:ok, user_id} ->
        if current_user.id == user_id do
          with {:ok, %User{}} <- OjolMvp.Accounts.delete_user(current_user) do
            # Revoke all user tokens when deleting account
            revoke_user_tokens(current_user.id)

            conn
            |> put_status(:ok)
            |> json(%{message: "Account deleted successfully"})
          end
        else
          unauthorized_response(conn)
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid user ID"})
    end
  end

  @doc """
  Update user location with validation
  """
  def update_location(conn, %{"id" => user_id, "latitude" => lat, "longitude" => lng}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(user_id) do
      {:ok, id} ->
        if current_user.id == id do
          case validate_coordinates(lat, lng) do
            :ok ->
              case OjolMvp.Accounts.update_user_location(id, lat, lng) do
                {:ok, user} ->
                  safe_user = Map.take(user, [:id, :latitude, :longitude, :updated_at])
                  json(conn, %{data: safe_user, message: "Location updated successfully"})

                {:error, %Ecto.Changeset{} = changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> put_view(json: OjolMvpWeb.ChangesetJSON)
                  |> render(:error, changeset: changeset)

                {:error, reason} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> json(%{error: reason})
              end

            {:error, message} ->
              conn
              |> put_status(:bad_request)
              |> json(%{error: message})
          end
        else
          unauthorized_response(conn)
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid user ID"})
    end
  end

  # Private functions

  defp validate_create_params(params) do
    required_fields = ["password", "name", "phone", "type"]

    cond do
      !is_map(params) ->
        {:error, "Invalid user data format"}

      Enum.any?(required_fields, &(is_nil(params[&1]) or params[&1] == "")) ->
        {:error, "Missing required fields: #{Enum.join(required_fields, ", ")}"}

      params["type"] not in ["customer", "driver"] ->
        {:error, "Type must be either 'customer' or 'driver'"}

      String.length(params["password"]) < 6 ->
        {:error, "Password must be at least 6 characters long"}

      !valid_phone?(params["phone"]) ->
        {:error, "Invalid phone number format"}

      true ->
        :ok
    end
  end

  defp validate_update_params(params) do
    cond do
      !is_map(params) ->
        {:error, "Invalid user data format"}

      params["phone"] && !valid_phone?(params["phone"]) ->
        {:error, "Invalid phone number format"}

      params["password"] && String.length(params["password"]) < 6 ->
        {:error, "Password must be at least 6 characters long"}

      params["type"] && params["type"] not in ["customer", "driver"] ->
        {:error, "Type must be either 'customer' or 'driver'"}

      true ->
        :ok
    end
  end

  defp validate_coordinates(lat, lng) do
    cond do
      !is_number(lat) and !is_binary(lat) ->
        {:error, "Latitude must be a number"}

      !is_number(lng) and !is_binary(lng) ->
        {:error, "Longitude must be a number"}

      true ->
        case {parse_float(lat), parse_float(lng)} do
          {{:ok, lat_val}, {:ok, lng_val}} ->
            cond do
              lat_val < -90.0 or lat_val > 90.0 ->
                {:error, "Latitude must be between -90 and 90"}

              lng_val < -180.0 or lng_val > 180.0 ->
                {:error, "Longitude must be between -180 and 180"}

              true ->
                :ok
            end

          _ ->
            {:error, "Invalid coordinate values"}
        end
    end
  end

  defp parse_integer(value) when is_integer(value), do: {:ok, value}

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  defp parse_integer(_), do: :error

  defp parse_float(value) when is_float(value), do: {:ok, value}
  defp parse_float(value) when is_integer(value), do: {:ok, value * 1.0}

  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} -> {:ok, float}
      _ -> :error
    end
  end

  defp parse_float(_), do: :error

  defp valid_phone?(phone) do
    # Indonesian phone number format validation - aligned with User model
    phone_regex = ~r/^\+62[0-9]{9,12}$/
    Regex.match?(phone_regex, phone)
  end

  defp unauthorized_response(conn) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: "You can only access your own data"})
  end

  defp rate_limit_create(conn, _opts) do
    # Implement rate limiting logic here
    # For now, just pass through
    conn
  end

  defp revoke_user_tokens(_user_id) do
    # Implement token revocation logic
    # This would typically involve blacklisting tokens or updating a token version
    :ok
  end
end
