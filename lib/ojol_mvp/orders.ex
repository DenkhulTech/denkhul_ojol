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

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a order.

  ## Examples

      iex> delete_order(order)
      {:ok, %Order{}}

      iex> delete_order(order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{data: %Order{}}

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
    error -> error
  end
end
end
