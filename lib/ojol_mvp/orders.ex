defmodule OjolMvp.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias OjolMvp.Repo

  alias OjolMvp.Orders.Order

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders()
      [%Order{}, ...]

  """
  def list_orders do
    Repo.all(Order)
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(id), do: Repo.get!(Order, id)

  @doc """
  Creates a order.
  """
  def create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a order.
  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a order.
  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.
  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  def list_available_orders(_driver_lat \\ nil, _driver_lng \\ nil, _radius_km \\ 10.0) do
    from(o in Order,
      where: o.status == "pending" and is_nil(o.driver_id),
      order_by: [desc: o.inserted_at]
    )
    |> Repo.all()
  end

  def accept_order(order_id, driver_id) do
    order = get_order!(order_id)

    if order.status == "pending" and is_nil(order.driver_id) do
      update_order(order, %{driver_id: driver_id, status: "accepted"})
    else
      {:error, "Order not available"}
    end
  end

  def start_trip(order_id) do
    order = get_order!(order_id)

    if order.status == "accepted" do
      update_order(order, %{status: "in_progress"})
    else
      {:error, "Order not ready to start"}
    end
  end

  def complete_trip(order_id) do
    order = get_order!(order_id)

    if order.status == "in_progress" do
      update_order(order, %{status: "completed"})
    else
      {:error, "Order not in progress"}
    end
  end

  def get_active_order_for_driver(driver_id) do
    from(o in Order,
      where: o.driver_id == ^driver_id and o.status in ["accepted", "in_progress"],
      limit: 1
    )
    |> Repo.one()
  end

  def create_order_with_broadcast(order_params) do
    case create_order(order_params) do
      {:ok, order} ->
        # Broadcast new order to available drivers
        OjolMvpWeb.OrderChannel.broadcast_new_order(order)
        {:ok, order}

      error ->
        error
    end
  end

  def create_order_with_smart_pricing(attrs) do
    attrs_with_calculations =
      attrs
      |> calculate_distance_and_price()
      |> add_route_information()

    case create_order(attrs_with_calculations) do
      {:ok, order} ->
        OjolMvpWeb.OrderChannel.broadcast_new_order(order)
        {:ok, order}

      error ->
        error
    end
  end

  defp calculate_distance_and_price(attrs) do
    pickup_lat = attrs["pickup_lat"] || attrs[:pickup_lat]
    pickup_lng = attrs["pickup_lng"] || attrs[:pickup_lng]
    dest_lat = attrs["destination_lat"] || attrs[:destination_lat]
    dest_lng = attrs["destination_lng"] || attrs[:destination_lng]

    if pickup_lat && pickup_lng && dest_lat && dest_lng do
      distance =
        OjolMvp.Geo.DistanceCalculator.haversine_distance(
          pickup_lat,
          pickup_lng,
          dest_lat,
          dest_lng
        )

      price = OjolMvp.Geo.DistanceCalculator.calculate_price(distance)

      attrs
      |> Map.put("distance_km", distance)
      |> Map.put("price", price)
    else
      attrs
    end
  end

  defp add_route_information(attrs) do
    pickup_lat = attrs["pickup_lat"] || attrs[:pickup_lat]
    pickup_lng = attrs["pickup_lng"] || attrs[:pickup_lng]
    dest_lat = attrs["destination_lat"] || attrs[:destination_lat]
    dest_lng = attrs["destination_lng"] || attrs[:destination_lng]

    case OjolMvp.Maps.RoutingService.get_route(pickup_lat, pickup_lng, dest_lat, dest_lng) do
      {:ok, route_info} ->
        attrs
        |> Map.put("estimated_duration", round(route_info.duration_min))
        |> Map.put("route_geometry", route_info.geometry)

      {:error, _} ->
        attrs
    end
  end
end
