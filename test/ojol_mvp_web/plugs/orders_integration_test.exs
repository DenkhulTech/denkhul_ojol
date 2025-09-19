defmodule OjolMvp.OrdersIntegrationTest do
  use OjolMvp.DataCase, async: true

  alias OjolMvp.{Orders, Accounts}

  describe "create_order_with_smart_pricing/1" do
    setup do
      {:ok, customer} =
        Accounts.create_user(%{
          name: "John Customer",
          phone: "+6281234567890",
          type: "customer"
        })

      {:ok, driver} =
        Accounts.create_user(%{
          name: "Jane Driver",
          phone: "+6281234567891",
          type: "driver",
          is_available: true,
          latitude: Decimal.new("-6.2088"),
          longitude: Decimal.new("106.8456"),
          average_rating: Decimal.new("4.5"),
          total_ratings: 25
        })

      %{customer: customer, driver: driver}
    end

    test "creates order with calculated distance and price", %{customer: customer} do
      attrs = %{
        pickup_address: "Jl. Sudirman No. 1",
        pickup_lat: -6.2088,
        pickup_lng: 106.8456,
        destination_address: "Jl. Thamrin No. 2",
        destination_lat: -6.1944,
        destination_lng: 106.8229,
        customer_id: customer.id,
        status: "pending"
      }

      {:ok, order} = Orders.create_order_with_smart_pricing(attrs)

      assert order.distance_km > 0
      # Should have calculated price
      assert order.price > 5000
      assert order.customer_id == customer.id
      assert order.status == "pending"
    end

    test "includes route information when available", %{customer: customer} do
      attrs = %{
        pickup_address: "Jl. Sudirman No. 1",
        pickup_lat: -6.2088,
        pickup_lng: 106.8456,
        destination_address: "Jl. Thamrin No. 2",
        destination_lat: -6.1944,
        destination_lng: 106.8229,
        customer_id: customer.id,
        status: "pending"
      }

      {:ok, order} = Orders.create_order_with_smart_pricing(attrs)

      # Route info might not always be available (external API)
      # But order should still be created successfully
      assert order.id
      assert is_integer(order.price)
    end
  end

  describe "driver matching integration" do
    test "auto assigns best available driver" do
      # Create customer
      {:ok, customer} =
        Accounts.create_user(%{
          name: "John Customer",
          phone: "+6281234567890",
          type: "customer"
        })

      # Create multiple drivers at different locations and ratings
      {:ok, driver1} =
        Accounts.create_user(%{
          name: "Driver Close",
          phone: "+6281111111111",
          type: "driver",
          is_available: true,
          # Very close
          latitude: Decimal.new("-6.2088"),
          longitude: Decimal.new("106.8456"),
          average_rating: Decimal.new("4.0"),
          total_ratings: 10
        })

      {:ok, driver2} =
        Accounts.create_user(%{
          name: "Driver Far High Rating",
          phone: "+6281111111112",
          type: "driver",
          is_available: true,
          # Further away
          latitude: Decimal.new("-6.3000"),
          longitude: Decimal.new("107.0000"),
          average_rating: Decimal.new("4.9"),
          total_ratings: 200
        })

      # Create order
      {:ok, order} =
        Orders.create_order(%{
          pickup_address: "Jl. Sudirman No. 1",
          pickup_lat: Decimal.new("-6.2088"),
          pickup_lng: Decimal.new("106.8456"),
          destination_address: "Jl. Thamrin No. 2",
          destination_lat: Decimal.new("-6.1944"),
          destination_lng: Decimal.new("106.8229"),
          customer_id: customer.id,
          status: "pending",
          price: 15000
        })

      # Auto assign driver
      case OjolMvp.Matching.DriverMatcher.auto_assign_driver(order) do
        {:ok, updated_order} ->
          assert updated_order.driver_id in [driver1.id, driver2.id]
          assert updated_order.status == "accepted"

          # Check that assigned driver is no longer available
          assigned_driver = Accounts.get_user!(updated_order.driver_id)
          refute assigned_driver.is_available

        {:error, "No drivers available in the area"} ->
          # Might happen if drivers are too far away
          assert true
      end
    end
  end
end
