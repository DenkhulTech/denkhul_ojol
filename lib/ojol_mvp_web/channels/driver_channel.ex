defmodule OjolMvpWeb.DriverChannel do
  use OjolMvpWeb, :channel

  @impl true
  def join("driver:available", _payload, socket) do
    try do
      if socket.assigns.user.type == "driver" do
        {:ok, socket}
      else
        {:error, %{reason: "drivers_only"}}
      end
    rescue
      _ -> {:error, %{reason: "internal_error"}}
    end
  end

  @impl true
  def join("driver:" <> driver_id, _payload, socket) do
    try do
      case Integer.parse(driver_id) do
        {id, ""} ->
          if socket.assigns.user.id == id do
            {:ok, socket}
          else
            {:error, %{reason: "unauthorized"}}
          end

        _ ->
          {:error, %{reason: "invalid_driver_id"}}
      end
    rescue
      _ -> {:error, %{reason: "internal_error"}}
    end
  end

  @impl true
  def handle_in("location_update", %{"lat" => lat, "lng" => lng}, socket) do
    try do
      OjolMvp.Accounts.update_user_location(socket.assigns.user.id, lat, lng)
      broadcast_driver_location(socket.assigns.user.id, lat, lng)
      {:noreply, socket}
    rescue
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_in("availability_update", %{"is_available" => available}, socket) do
    try do
      user = socket.assigns.user
      OjolMvp.Accounts.update_user(user, %{is_available: available})
      {:noreply, socket}
    rescue
      _ -> {:noreply, socket}
    end
  end

  defp broadcast_driver_location(driver_id, lat, lng) do
    try do
      case OjolMvp.Orders.get_active_order_for_driver(driver_id) do
        nil ->
          :ok

        order ->
          OjolMvpWeb.Endpoint.broadcast("order:#{order.id}", "driver_location_update", %{
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.utc_now()
          })
      end
    rescue
      _ -> :ok
    end
  end
end
