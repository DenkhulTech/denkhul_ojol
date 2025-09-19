defmodule OjolMvpWeb.Plugs.AuthErrorHandler do
  import Plug.Conn, only: [put_status: 2]
  import Phoenix.Controller, only: [json: 2]

  def auth_error(conn, {type, _reason}, _opts) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: to_string(type)})
  end
end
