defmodule OjolMvpWeb.OrderChannel do
  use OjolMvpWeb, :channel

  @impl true
  def join("order:" <> order_id, _payload, socket) do
    case authorize_order_access(socket.assigns.user, order_id) do
      :ok -> {:ok, socket}
      :error -> {:error, %{reason: "unauthorized"}}
    end
  end

  defp authorize_order_access(user, order_id) do
    case OjolMvp.Orders.get_order!(order_id) do
      nil ->
        :error

      order ->
        # Only customer or assigned driver can join order channel
        if user.id == order.customer_id or user.id == order.driver_id do
          :ok
        else
          :error
        end
    end
  end

  @impl true
  @spec handle_in(<<_::120, _::_*32>>, map(), Phoenix.Socket.t()) ::
          {:noreply, Phoenix.Socket.t()}
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

end
