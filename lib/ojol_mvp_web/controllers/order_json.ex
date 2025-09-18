defmodule OjolMvpWeb.OrderJSON do
  alias OjolMvp.Orders.Order

  def index(%{orders: orders}) do
    %{data: for(order <- orders, do: data(order))}
  end

  def show(%{order: order}) do
    %{data: data(order)}
  end

  defp data(%Order{} = order) do
    %{
      id: order.id,
      pickup_address: order.pickup_address,
      pickup_lat: decimal_to_float(order.pickup_lat),
      pickup_lng: decimal_to_float(order.pickup_lng),
      destination_address: order.destination_address,
      destination_lat: decimal_to_float(order.destination_lat),
      destination_lng: decimal_to_float(order.destination_lng),
      distance_km: decimal_to_float(order.distance_km),
      price: order.price,
      status: order.status,
      notes: order.notes,
      customer_id: order.customer_id,
      driver_id: order.driver_id
    }
  end

  defp decimal_to_float(nil), do: nil
  defp decimal_to_float(decimal), do: Decimal.to_float(decimal)
end
