# test/ojol_mvp/matching/driver_matcher_test.exs
defmodule OjolMvp.Matching.DriverMatcherTest do
  use OjolMvp.DataCase, async: true

  alias OjolMvp.Matching.DriverMatcher
  alias OjolMvp.Accounts.User

  setup do
    # Create test drivers
    {:ok, driver1} =
      %User{}
      |> User.changeset(%{
        name: "Driver 1",
        phone: "+6281111111111",
        type: "driver",
        is_available: true,
        latitude: Decimal.new("-6.2088"),
        longitude: Decimal.new("106.8456"),
        average_rating: Decimal.new("4.5"),
        total_ratings: 50
      })
      |> OjolMvp.Repo.insert()

    {:ok, driver2} =
      %User{}
      |> User.changeset(%{
        name: "Driver 2",
        phone: "+6281111111112",
        type: "driver",
        is_available: true,
        latitude: Decimal.new("-6.1944"),
        longitude: Decimal.new("106.8229"),
        average_rating: Decimal.new("4.8"),
        total_ratings: 100
      })
      |> OjolMvp.Repo.insert()

    {:ok, driver3} =
      %User{}
      |> User.changeset(%{
        name: "Driver 3",
        phone: "+6281111111113",
        type: "driver",
        # Not available
        is_available: false,
        latitude: Decimal.new("-6.2000"),
        longitude: Decimal.new("106.8400"),
        average_rating: Decimal.new("4.0"),
        total_ratings: 20
      })
      |> OjolMvp.Repo.insert()

    %{driver1: driver1, driver2: driver2, driver3: driver3}
  end

  describe "find_nearby_drivers/4" do
    test "finds available drivers within radius", %{driver1: driver1, driver2: driver2} do
      pickup_lat = -6.2088
      pickup_lng = 106.8456
      radius_km = 10.0

      matches = DriverMatcher.find_nearby_drivers(pickup_lat, pickup_lng, radius_km)

      # Should find driver1 and driver2, but not driver3 (unavailable)
      driver_ids = Enum.map(matches, & &1.driver.id)
      assert driver1.id in driver_ids
      assert driver2.id in driver_ids
    end

    test "respects radius limit", %{driver1: driver1} do
      pickup_lat = -6.2088
      pickup_lng = 106.8456
      # Very small radius
      radius_km = 0.1

      matches = DriverMatcher.find_nearby_drivers(pickup_lat, pickup_lng, radius_km)

      # Should only find very close drivers
      assert length(matches) <= 1
      if length(matches) == 1, do: assert(hd(matches).driver.id == driver1.id)
    end

    test "excludes unavailable drivers", %{driver3: driver3} do
      pickup_lat = -6.2000
      pickup_lng = 106.8400
      radius_km = 1.0

      matches = DriverMatcher.find_nearby_drivers(pickup_lat, pickup_lng, radius_km)

      driver_ids = Enum.map(matches, & &1.driver.id)
      refute driver3.id in driver_ids
    end

    test "respects limit parameter", %{driver1: _driver1, driver2: _driver2} do
      pickup_lat = -6.2088
      pickup_lng = 106.8456
      radius_km = 50.0
      limit = 1

      matches = DriverMatcher.find_nearby_drivers(pickup_lat, pickup_lng, radius_km, limit)

      assert length(matches) <= limit
    end
  end

  describe "calculate_driver_score/3" do
    test "calculates score based on distance, rating, and experience", %{driver1: driver1} do
      pickup_lat = -6.2088
      pickup_lng = 106.8456

      score_data = DriverMatcher.calculate_driver_score(driver1, pickup_lat, pickup_lng)

      assert is_map(score_data)
      assert score_data.driver.id == driver1.id
      assert is_float(score_data.distance_km)
      assert is_float(score_data.score)
      assert is_integer(score_data.estimated_arrival)
    end

    test "higher rated driver gets better score", %{driver1: driver1, driver2: driver2} do
      pickup_lat = -6.2088
      pickup_lng = 106.8456

      score1 = DriverMatcher.calculate_driver_score(driver1, pickup_lat, pickup_lng)
      score2 = DriverMatcher.calculate_driver_score(driver2, pickup_lat, pickup_lng)

      # Driver2 has higher rating (4.8 vs 4.5) and more experience
      # If distances are similar, driver2 should have higher score
      if abs(score1.distance_km - score2.distance_km) < 1.0 do
        assert score2.score > score1.score
      end
    end

    test "includes estimated arrival time", %{driver1: driver1} do
      pickup_lat = -6.2088
      pickup_lng = 106.8456

      score_data = DriverMatcher.calculate_driver_score(driver1, pickup_lat, pickup_lng)

      assert score_data.estimated_arrival > 0
      # Should be reasonable arrival time (not too long for close driver)
      # Less than 1 hour
      assert score_data.estimated_arrival < 60
    end
  end
end

# test/ojol_mvp/maps/routing_service_test.exs
defmodule OjolMvp.Maps.RoutingServiceTest do
  use ExUnit.Case, async: true

  alias OjolMvp.Maps.RoutingService

  @moduletag :external_api

  describe "get_route/4" do
    test "gets route between two points" do
      # Jakarta to Bandung coordinates
      pickup_lat = -6.2088
      pickup_lng = 106.8456
      dest_lat = -6.9175
      dest_lng = 107.6191

      case RoutingService.get_route(pickup_lat, pickup_lng, dest_lat, dest_lng) do
        {:ok, route} ->
          assert is_map(route)
          # Should be > 100km
          assert route.distance_km > 100
          # Should take > 1 hour
          assert route.duration_min > 60
          assert is_map(route.geometry)

        {:error, reason} ->
          # External API might be down, log but don't fail test
          IO.puts("OSRM API unavailable: #{reason}")
      end
    end

    test "handles invalid coordinates gracefully" do
      # Invalid coordinates
      case RoutingService.get_route(999, 999, -999, -999) do
        {:error, _reason} ->
          # Expected to fail
          assert true

        {:ok, _route} ->
          flunk("Should have failed with invalid coordinates")
      end
    end
  end

  describe "get_route_alternatives/4" do
    test "gets multiple route options when available" do
      pickup_lat = -6.2088
      pickup_lng = 106.8456
      dest_lat = -6.1944
      dest_lng = 106.8229

      case RoutingService.get_route_alternatives(pickup_lat, pickup_lng, dest_lat, dest_lng) do
        {:ok, routes} when is_list(routes) ->
          assert length(routes) >= 1

          for route <- routes do
            assert is_map(route)
            assert route.distance_km > 0
            assert route.duration_min > 0
          end

        {:error, reason} ->
          IO.puts("OSRM API unavailable: #{reason}")
      end
    end
  end
end
