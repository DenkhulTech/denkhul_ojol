defmodule OjolMvpWeb.UserSocket do
  use Phoenix.Socket
  require Logger

  channel "order:*", OjolMvpWeb.OrderChannel
  channel "driver:*", OjolMvpWeb.DriverChannel

  @impl true
  def connect(%{"user_id" => user_id, "token" => token}, socket, _connect_info) do
    with {:ok, user_id} <- parse_user_id(user_id),
         {:ok, %{"sub" => token_user_id}} <- OjolMvp.Guardian.decode_and_verify(token),
         true <- to_string(user_id) == token_user_id,
         {:ok, user} <- OjolMvp.Accounts.get_user(user_id) do
      {:ok, assign(socket, :user, user)}
    else
      error ->
        Logger.debug("Socket connection failed: #{inspect(error)}")
        :error
    end
  end

  def connect(_, _, _), do: :error

  defp parse_user_id(user_id) when is_integer(user_id), do: {:ok, user_id}

  defp parse_user_id(user_id) when is_binary(user_id) do
    case Integer.parse(user_id) do
      {id, ""} -> {:ok, id}
      _ -> {:error, :invalid_user_id}
    end
  end

  defp parse_user_id(_), do: {:error, :invalid_user_id}

  @impl true
  def id(socket) do
    try do
      "user_socket:#{socket.assigns.user.id}"
    rescue
      _ -> nil
    end
  end
end
