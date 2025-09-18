defmodule OjolMvpWeb.OrderChannel do
  use OjolMvpWeb, :channel

  @impl true
  def join("order:" <> order_id, _payload, socket) do
    case authorize_order_access(socket.assigns.user_id, order_id) do
      :ok -> {:ok, socket}
      :error -> {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("order_status_update", %{"status" => status}, socket) do
    # Broadcast status update to all subscribers
    broadcast(socket, "status_changed", %{
      status: status,
      timestamp: DateTime.utc_now()
    })
    {:noreply, socket}
  end

  @impl true
  def handle_in("driver_location", %{"lat" => lat, "lng" => lng}, socket) do
    # Broadcast driver location to customer
    broadcast(socket, "driver_location_update", %{
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.utc_now()
    })
    {:noreply, socket}
  end

  # Broadcast new order to available drivers
  def broadcast_new_order(order) do
    OjolMvpWeb.Endpoint.broadcast("driver:available", "new_order", %{
      order_id: order.id,
      pickup_address: order.pickup_address,
      destination_address: order.destination_address,
      pickup_lat: Decimal.to_float(order.pickup_lat),
      pickup_lng: Decimal.to_float(order.pickup_lng),
      price: order.price,
      distance_km: Decimal.to_float(order.distance_km)
    })
  end

  defp authorize_order_access(_user_id, _order_id) do
    # Simplified authorization - in production add proper checks
    :ok
  end
end
