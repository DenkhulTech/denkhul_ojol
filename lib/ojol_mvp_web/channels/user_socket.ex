defmodule OjolMvpWeb.UserSocket do
  use Phoenix.Socket

  # Channels for real-time features
  channel "order:*", OjolMvpWeb.OrderChannel
  channel "driver:*", OjolMvpWeb.DriverChannel
  channel "location:*", OjolMvpWeb.LocationChannel

  # Socket params for authentication (simplified for now)
  @impl true
  def connect(%{"user_id" => user_id, "user_type" => user_type}, socket, _connect_info) do
    {:ok, assign(socket, :user_id, user_id) |> assign(:user_type, user_type)}
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
