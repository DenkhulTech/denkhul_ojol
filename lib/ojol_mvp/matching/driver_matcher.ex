defmodule OjolMvp.Matching.DriverMatcher do
  alias OjolMvp.{Accounts, Geo.DistanceCalculator}
  alias OjolMvp.Accounts.User
  import Ecto.Query

  @doc """
  Find available drivers within radius, sorted by distance and rating
  """
  def find_nearby_drivers(pickup_lat, pickup_lng, radius_km \\ 5.0, limit \\ 10) do
    from(u in User,
      where: u.type == "driver" and u.is_available == true,
      where: not is_nil(u.latitude) and not is_nil(u.longitude),
      select: u
    )
    |> OjolMvp.Repo.all()
    |> filter_by_distance(pickup_lat, pickup_lng, radius_km)
    |> sort_by_score()
    |> Enum.take(limit)
  end

  @doc """
  Calculate driver score based on distance, rating, and availability
  """
  def calculate_driver_score(driver, pickup_lat, pickup_lng) do
    distance =
      DistanceCalculator.haversine_distance(
        pickup_lat,
        pickup_lng,
        driver.latitude,
        driver.longitude
      )

    # Lower distance = higher score (max 50 points)
    distance_score = max(0, 50 - distance * 10)

    # Rating score (max 30 points)
    rating_score = Decimal.to_float(driver.average_rating || Decimal.new(0)) * 6

    # Experience score based on total ratings (max 20 points)
    experience_score = min(20, (driver.total_ratings || 0) * 0.5)

    total_score = distance_score + rating_score + experience_score

    %{
      driver: driver,
      distance_km: distance,
      score: Float.round(total_score, 2),
      estimated_arrival: DistanceCalculator.estimate_duration(distance, 30)
    }
  end

  @doc """
  Auto-assign best available driver to order
  """
  def auto_assign_driver(order, radius_km \\ 5.0) do
    case find_nearby_drivers(order.pickup_lat, order.pickup_lng, radius_km, 1) do
      [] ->
        {:error, "No drivers available in the area"}

      [best_match | _] ->
        # Update driver availability
        Accounts.update_user(best_match.driver, %{is_available: false})

        # Assign to order
        OjolMvp.Orders.update_order(order, %{
          driver_id: best_match.driver.id,
          status: "accepted"
        })
    end
  end

  defp filter_by_distance(drivers, pickup_lat, pickup_lng, radius_km) do
    drivers
    |> Enum.map(fn driver ->
      distance =
        DistanceCalculator.haversine_distance(
          pickup_lat,
          pickup_lng,
          driver.latitude,
          driver.longitude
        )

      {driver, distance}
    end)
    |> Enum.filter(fn {_driver, distance} -> distance <= radius_km end)
    |> Enum.map(fn {driver, _distance} ->
      calculate_driver_score(driver, pickup_lat, pickup_lng)
    end)
  end

  defp sort_by_score(driver_matches) do
    Enum.sort_by(driver_matches, & &1.score, :desc)
  end
end
