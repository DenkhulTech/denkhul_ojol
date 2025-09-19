defmodule OjolMvpWeb.FallbackController do
  use OjolMvpWeb, :controller

  require Logger

  # Handle changeset errors (validation errors)
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    errors = format_changeset_errors(changeset)

    Logger.warning("Validation error: #{inspect(errors)}")

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      error: "Validation failed",
      details: errors,
      timestamp: DateTime.utc_now()
    })
  end

  # Handle not found errors
  def call(conn, {:error, :not_found}) do
    Logger.info("Resource not found - Path: #{conn.request_path}")

    conn
    |> put_status(:not_found)
    |> json(%{
      error: "Resource not found",
      timestamp: DateTime.utc_now()
    })
  end

  # Handle unauthorized access
  def call(conn, {:error, :unauthorized}) do
    Logger.warning("Unauthorized access attempt - Path: #{conn.request_path}")

    conn
    |> put_status(:unauthorized)
    |> json(%{
      error: "Authentication required",
      timestamp: DateTime.utc_now()
    })
  end

  # Handle forbidden access
  def call(conn, {:error, :forbidden}) do
    Logger.warning(
      "Forbidden access attempt - Path: #{conn.request_path}, User: #{get_user_id(conn)}"
    )

    conn
    |> put_status(:forbidden)
    |> json(%{
      error: "Access denied",
      timestamp: DateTime.utc_now()
    })
  end

  # Handle custom string errors
  def call(conn, {:error, message}) when is_binary(message) do
    Logger.warning("Custom error: #{message}")

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      error: message,
      timestamp: DateTime.utc_now()
    })
  end

  # Handle atom errors
  def call(conn, {:error, reason}) when is_atom(reason) do
    error_message = humanize_error(reason)

    Logger.warning("Error: #{reason}")

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      error: error_message,
      timestamp: DateTime.utc_now()
    })
  end

  # Handle database constraint errors
  def call(conn, {:error, %Ecto.ConstraintError{} = error}) do
    error_message = format_constraint_error(error)

    Logger.error("Database constraint error: #{inspect(error)}")

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      error: error_message,
      timestamp: DateTime.utc_now()
    })
  end

  # Handle timeout errors
  def call(conn, {:error, :timeout}) do
    Logger.error("Request timeout - Path: #{conn.request_path}")

    conn
    |> put_status(:request_timeout)
    |> json(%{
      error: "Request timeout. Please try again.",
      timestamp: DateTime.utc_now()
    })
  end

  # Handle generic errors
  def call(conn, {:error, error}) do
    Logger.error("Unexpected error: #{inspect(error)}")

    # Don't expose internal error details in production
    error_message =
      if Mix.env() == :prod do
        "An unexpected error occurred"
      else
        "Error: #{inspect(error)}"
      end

    conn
    |> put_status(:internal_server_error)
    |> json(%{
      error: error_message,
      timestamp: DateTime.utc_now()
    })
  end

  # Catch-all for any other patterns
  def call(conn, error) do
    Logger.error("Unhandled error pattern: #{inspect(error)}")

    error_message =
      if Mix.env() == :prod do
        "An unexpected error occurred"
      else
        "Unhandled error: #{inspect(error)}"
      end

    conn
    |> put_status(:internal_server_error)
    |> json(%{
      error: error_message,
      timestamp: DateTime.utc_now()
    })
  end

  # Private helper functions

  defp format_changeset_errors(%Ecto.Changeset{errors: errors}) do
    Enum.map(errors, fn {field, {message, opts}} ->
      # Handle validation options
      formatted_message =
        case opts do
          [validation: :required] ->
            "is required"

          [validation: :length, min: min] ->
            "must be at least #{min} characters"

          [validation: :length, max: max] ->
            "must not exceed #{max} characters"

          [validation: :length, min: min, max: max] ->
            "must be between #{min} and #{max} characters"

          [validation: :format] ->
            "has invalid format"

          [validation: :unique] ->
            "has already been taken"

          [validation: :number, greater_than: num] ->
            "must be greater than #{num}"

          [validation: :number, less_than: num] ->
            "must be less than #{num}"

          [validation: :inclusion] ->
            "is not included in the list"

          _ ->
            message
        end

      %{
        field: field,
        message: formatted_message
      }
    end)
  end

  defp format_constraint_error(%Ecto.ConstraintError{constraint: constraint, type: type}) do
    case {type, constraint} do
      {:unique, _} -> "This record already exists"
      {:foreign_key, _} -> "Referenced record does not exist"
      {:check, _} -> "Invalid data provided"
      _ -> "Database constraint violation"
    end
  end

  defp humanize_error(:not_found), do: "Resource not found"
  defp humanize_error(:unauthorized), do: "Authentication required"
  defp humanize_error(:forbidden), do: "Access denied"
  defp humanize_error(:invalid_credentials), do: "Invalid email or password"
  defp humanize_error(:account_locked), do: "Account has been locked"
  defp humanize_error(:token_expired), do: "Authentication token has expired"
  defp humanize_error(:invalid_token), do: "Invalid authentication token"
  defp humanize_error(:email_not_confirmed), do: "Please confirm your email address"
  defp humanize_error(:already_exists), do: "Record already exists"
  defp humanize_error(:invalid_params), do: "Invalid parameters provided"
  defp humanize_error(:service_unavailable), do: "Service temporarily unavailable"
  defp humanize_error(reason), do: "Error: #{reason}"

  defp get_user_id(conn) do
    case Guardian.Plug.current_resource(conn) do
      %{id: id} -> id
      _ -> "unknown"
    end
  end
end
