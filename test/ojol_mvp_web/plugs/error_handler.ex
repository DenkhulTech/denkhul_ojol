defmodule OjolMvpWeb.Plugs.ErrorHandler do
  import Plug.Conn, only: [put_status: 2]
  import Phoenix.Controller, only: [json: 2]
  require Logger

  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    Logger.error("#{kind}: #{inspect(reason)}\n#{Exception.format_stacktrace(stack)}")

    case reason do
      %Ecto.NoResultsError{} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Resource not found"})

      %Ecto.ConstraintError{} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Data constraint violation"})

      %Jason.DecodeError{} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid JSON format"})

      _ ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Internal server error"})
    end
  end
end
