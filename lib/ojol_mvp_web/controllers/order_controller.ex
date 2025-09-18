defmodule OjolMvpWeb.OrderController do
  use OjolMvpWeb, :controller

  alias OjolMvp.Orders
  alias OjolMvp.Orders.Order

  action_fallback OjolMvpWeb.FallbackController

  def index(conn, _params) do
    orders = Orders.list_orders()
    render(conn, :index, orders: orders)
  end

def create(conn, %{"order" => order_params}) do
  with {:ok, %Order{} = order} <- Orders.create_order(order_params) do
    # Add broadcast for new order
    if order.status == "pending" do
      OjolMvpWeb.OrderChannel.broadcast_new_order(order)
    end

    conn
    |> put_status(:created)
    |> put_resp_header("location", ~p"/api/orders/#{order}")
    |> render(:show, order: order)
  end
end

  def show(conn, %{"id" => id}) do
    order = Orders.get_order!(id)
    render(conn, :show, order: order)
  end

  def update(conn, %{"id" => id, "order" => order_params}) do
    order = Orders.get_order!(id)

    with {:ok, %Order{} = order} <- Orders.update_order(order, order_params) do
      render(conn, :show, order: order)
    end
  end

  def delete(conn, %{"id" => id}) do
    order = Orders.get_order!(id)

    with {:ok, %Order{}} <- Orders.delete_order(order) do
      send_resp(conn, :no_content, "")
    end
  end

  def available_orders(conn, params) do
  driver_lat = params["lat"]
  driver_lng = params["lng"]
  radius = params["radius"] || 10.0

  orders = Orders.list_available_orders(driver_lat, driver_lng, radius)
  render(conn, :index, orders: orders)
end

def accept(conn, %{"id" => order_id} = params) do
  driver_id = params["driver_id"]

  case Orders.accept_order(order_id, driver_id) do
    {:ok, order} ->
      # Broadcast order acceptance
      OjolMvpWeb.Endpoint.broadcast("order:#{order_id}", "status_changed", %{
        status: "accepted",
        driver_id: driver_id,
        message: "Driver accepted your order"
      })

      render(conn, :show, order: order)
    {:error, message} ->
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: message})
  end
end

def start_trip(conn, %{"id" => order_id}) do
  case Orders.start_trip(order_id) do
    {:ok, order} ->
      render(conn, :show, order: order)
    {:error, message} ->
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: message})
  end
end

def complete(conn, %{"id" => order_id}) do
  case Orders.complete_trip(order_id) do
    {:ok, order} ->
      render(conn, :show, order: order)
    {:error, message} ->
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: message})
  end
end

end
