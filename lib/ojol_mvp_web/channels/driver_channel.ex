defmodule OjolMvpWeb.DriverChannel do
  use OjolMvpWeb, :channel

  @impl true
  def join("driver:available", _payload, socket) do
    if socket.assigns.user.type == "driver" do
      {:ok, socket}
    else
      {:error, %{reason: "drivers_only"}}
    end
  end

  @impl true
  def join("driver:" <> driver_id, _payload, socket) do
    if socket.assigns.user.id == String.to_integer(driver_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("location_update", %{"lat" => lat, "lng" => lng}, socket) do
    OjolMvp.Accounts.update_user_location(socket.assigns.user.id, lat, lng)
    broadcast_driver_location(socket.assigns.user.id, lat, lng)
    {:noreply, socket}
  end

  @impl true
  def handle_in("availability_update", %{"is_available" => available}, socket) do
    # Update driver availability
    user = OjolMvp.Accounts.get_user!(socket.assigns.user_id)
    OjolMvp.Accounts.update_user(user, %{is_available: available})

    {:noreply, socket}
  end

  defp broadcast_driver_location(driver_id, lat, lng) do
    # Find active orders for this driver
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
  end
end
