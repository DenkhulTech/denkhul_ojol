defmodule OjolMvpWeb.OrderControllerTest do
  use OjolMvpWeb.ConnCase

  import OjolMvp.OrdersFixtures
  alias OjolMvp.Orders.Order

  @create_attrs %{
    status: "some status",
    pickup_address: "some pickup_address",
    pickup_lat: "120.5",
    pickup_lng: "120.5",
    destination_address: "some destination_address",
    destination_lat: "120.5",
    destination_lng: "120.5",
    distance_km: "120.5",
    price: 42,
    notes: "some notes"
  }
  @update_attrs %{
    status: "some updated status",
    pickup_address: "some updated pickup_address",
    pickup_lat: "456.7",
    pickup_lng: "456.7",
    destination_address: "some updated destination_address",
    destination_lat: "456.7",
    destination_lng: "456.7",
    distance_km: "456.7",
    price: 43,
    notes: "some updated notes"
  }
  @invalid_attrs %{status: nil, pickup_address: nil, pickup_lat: nil, pickup_lng: nil, destination_address: nil, destination_lat: nil, destination_lng: nil, distance_km: nil, price: nil, notes: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all orders", %{conn: conn} do
      conn = get(conn, ~p"/api/orders")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create order" do
    test "renders order when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/orders", order: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/orders/#{id}")

      assert %{
               "id" => ^id,
               "destination_address" => "some destination_address",
               "destination_lat" => "120.5",
               "destination_lng" => "120.5",
               "distance_km" => "120.5",
               "notes" => "some notes",
               "pickup_address" => "some pickup_address",
               "pickup_lat" => "120.5",
               "pickup_lng" => "120.5",
               "price" => 42,
               "status" => "some status"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/orders", order: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update order" do
    setup [:create_order]

    test "renders order when data is valid", %{conn: conn, order: %Order{id: id} = order} do
      conn = put(conn, ~p"/api/orders/#{order}", order: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/orders/#{id}")

      assert %{
               "id" => ^id,
               "destination_address" => "some updated destination_address",
               "destination_lat" => "456.7",
               "destination_lng" => "456.7",
               "distance_km" => "456.7",
               "notes" => "some updated notes",
               "pickup_address" => "some updated pickup_address",
               "pickup_lat" => "456.7",
               "pickup_lng" => "456.7",
               "price" => 43,
               "status" => "some updated status"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, order: order} do
      conn = put(conn, ~p"/api/orders/#{order}", order: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete order" do
    setup [:create_order]

    test "deletes chosen order", %{conn: conn, order: order} do
      conn = delete(conn, ~p"/api/orders/#{order}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/orders/#{order}")
      end
    end
  end

  defp create_order(_) do
    order = order_fixture()

    %{order: order}
  end
end
