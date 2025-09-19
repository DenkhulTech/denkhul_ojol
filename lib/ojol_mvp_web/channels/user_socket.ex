defmodule OjolMvpWeb.UserSocket do
  use Phoenix.Socket

  # Channels for real-time features
  channel "order:*", OjolMvpWeb.OrderChannel
  channel "driver:*", OjolMvpWeb.DriverChannel
  channel "location:*", OjolMvpWeb.LocationChannel

  # Socket params for authentication (simplified for now)
  @impl true
  def connect(%{"user_id" => user_id, "token" => token}, socket, _connect_info) do
    # Verify token first
    case OjolMvp.Guardian.decode_and_verify(token) do
      {:ok, %{"sub" => ^user_id}} ->
        case OjolMvp.Accounts.get_user(user_id) do
          {:ok, user} -> {:ok, assign(socket, :user, user)}
          {:error, _} -> :error
        end

      {:error, _} ->
        :error
    end
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user.id}"
end
