defmodule OjolMvpWeb.OrderChannel do
  use OjolMvpWeb, :channel
  require Logger

  @impl true
  def join("order:" <> order_id_str, _payload, socket) do
    with {:ok, order_id} <- parse_integer(order_id_str),
         :ok <- authorize_order_access(socket.assigns.user, order_id) do
      socket = assign(socket, :order_id, order_id)
      {:ok, socket}
    else
      {:error, reason} ->
        Logger.debug("Join failed: #{inspect(reason)}")
        {:error, %{reason: to_string(reason)}}
    end
  end

  @impl true
  def handle_in("order_status_update", payload, socket) do
    with %{"status" => status} <- payload,
         true <- valid_status?(status),
         order_id when is_integer(order_id) <- socket.assigns[:order_id],
         {:ok, _order} <- OjolMvp.Orders.update_order_status(order_id, status) do
      broadcast(socket, "status_changed", %{
        status: status,
        order_id: order_id,
        timestamp: DateTime.utc_now()
      })

      {:noreply, socket}
    else
      false ->
        push(socket, "error", %{message: "Invalid status"})
        {:noreply, socket}

      {:error, reason} ->
        push(socket, "error", %{message: "Failed to update: #{inspect(reason)}"})
        {:noreply, socket}

      _ ->
        push(socket, "error", %{message: "Invalid request"})
        {:noreply, socket}
    end
  end

  @impl true
  def handle_in("driver_location", payload, socket) do
    with %{"lat" => lat, "lng" => lng} <- payload,
         true <- valid_location?(lat, lng) do
      broadcast(socket, "driver_location_update", %{
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.utc_now()
      })

      {:noreply, socket}
    else
      _ ->
        {:reply, {:error, %{reason: "invalid coordinates"}}, socket}
    end
  end

  def handle_in(_event, _payload, socket) do
    Logger.debug("Unhandled event in OrderChannel")
    {:noreply, socket}
  end

  # Safe helper functions
  defp authorize_order_access(user, order_id) do
    case OjolMvp.Orders.get_order(order_id) do
      {:ok, order} ->
        if user.id in [order.customer_id, order.driver_id] do
          :ok
        else
          {:error, :unauthorized}
        end

      {:error, _} ->
        {:error, :not_found}
    end
  end

  defp parse_integer(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> {:error, :invalid_integer}
    end
  end

  defp valid_status?(status) when is_binary(status) do
    status in ["pending", "accepted", "pickup", "in_progress", "completed", "canceled"]
  end

  defp valid_status?(_), do: false

  defp valid_location?(lat, lng) when is_number(lat) and is_number(lng) do
    lat >= -90 and lat <= 90 and lng >= -180 and lng <= 180
  end

  defp valid_location?(_, _), do: false

  def broadcast_new_order(order) do
    try do
      if order && order.id do
        OjolMvpWeb.Endpoint.broadcast("driver:available", "new_order", %{
          order_id: order.id,
          pickup_address: order.pickup_address || "",
          destination_address: order.destination_address || "",
          pickup_lat: safe_to_float(order.pickup_lat),
          pickup_lng: safe_to_float(order.pickup_lng),
          total_fare: safe_to_float(order.total_fare),
          distance_km: safe_to_float(order.distance_km || 0)
        })
      end
    rescue
      e -> Logger.error("Broadcast failed: #{inspect(e)}")
    end
  end

  defp safe_to_float(%Decimal{} = decimal), do: Decimal.to_float(decimal)
  defp safe_to_float(value) when is_number(value), do: value

  defp safe_to_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> 0.0
    end
  end

  defp safe_to_float(_), do: 0.0
end
