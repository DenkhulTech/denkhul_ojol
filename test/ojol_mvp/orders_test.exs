defmodule OjolMvp.OrdersTest do
  use OjolMvp.DataCase

  alias OjolMvp.Orders

  describe "orders" do
    alias OjolMvp.Orders.Order

    import OjolMvp.OrdersFixtures

    @invalid_attrs %{status: nil, pickup_address: nil, pickup_lat: nil, pickup_lng: nil, destination_address: nil, destination_lat: nil, destination_lng: nil, distance_km: nil, price: nil, notes: nil}

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Orders.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Orders.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      valid_attrs = %{status: "some status", pickup_address: "some pickup_address", pickup_lat: "120.5", pickup_lng: "120.5", destination_address: "some destination_address", destination_lat: "120.5", destination_lng: "120.5", distance_km: "120.5", price: 42, notes: "some notes"}

      assert {:ok, %Order{} = order} = Orders.create_order(valid_attrs)
      assert order.status == "some status"
      assert order.pickup_address == "some pickup_address"
      assert order.pickup_lat == Decimal.new("120.5")
      assert order.pickup_lng == Decimal.new("120.5")
      assert order.destination_address == "some destination_address"
      assert order.destination_lat == Decimal.new("120.5")
      assert order.destination_lng == Decimal.new("120.5")
      assert order.distance_km == Decimal.new("120.5")
      assert order.price == 42
      assert order.notes == "some notes"
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orders.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      update_attrs = %{status: "some updated status", pickup_address: "some updated pickup_address", pickup_lat: "456.7", pickup_lng: "456.7", destination_address: "some updated destination_address", destination_lat: "456.7", destination_lng: "456.7", distance_km: "456.7", price: 43, notes: "some updated notes"}

      assert {:ok, %Order{} = order} = Orders.update_order(order, update_attrs)
      assert order.status == "some updated status"
      assert order.pickup_address == "some updated pickup_address"
      assert order.pickup_lat == Decimal.new("456.7")
      assert order.pickup_lng == Decimal.new("456.7")
      assert order.destination_address == "some updated destination_address"
      assert order.destination_lat == Decimal.new("456.7")
      assert order.destination_lng == Decimal.new("456.7")
      assert order.distance_km == Decimal.new("456.7")
      assert order.price == 43
      assert order.notes == "some updated notes"
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Orders.update_order(order, @invalid_attrs)
      assert order == Orders.get_order!(order.id)
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Orders.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(order.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Orders.change_order(order)
    end
  end
end
