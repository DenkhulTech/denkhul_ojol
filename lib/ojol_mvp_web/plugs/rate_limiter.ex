defmodule OjolMvpWeb.Plugs.RateLimiter do
  import Plug.Conn, only: [put_status: 2, halt: 1]
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, opts) do
    limit = opts[:limit] || 100
    window = opts[:window] || 60_000

    identifier = get_identifier(conn)

    case Hammer.check_rate("api:#{identifier}", window, limit) do
      {:allow, _count} ->
        conn

      {:deny, _limit} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Rate limit exceeded"})
        |> halt()
    end
  end

  defp get_identifier(conn) do
    case Guardian.Plug.current_resource(conn) do
      %{id: user_id} ->
        "user:#{user_id}"

      _ ->
        conn.remote_ip
        |> Tuple.to_list()
        |> Enum.join(".")
    end
  end
end
