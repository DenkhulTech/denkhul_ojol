defmodule OjolMvp.OrdersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OjolMvp.Orders` context.
  """

  @doc """
  Generate a order.
  """
  def order_fixture(attrs \\ %{}) do
    {:ok, order} =
      attrs
      |> Enum.into(%{
        destination_address: "some destination_address",
        destination_lat: "120.5",
        destination_lng: "120.5",
        distance_km: "120.5",
        notes: "some notes",
        pickup_address: "some pickup_address",
        pickup_lat: "120.5",
        pickup_lng: "120.5",
        price: 42,
        status: "some status"
      })
      |> OjolMvp.Orders.create_order()

    order
  end
end
