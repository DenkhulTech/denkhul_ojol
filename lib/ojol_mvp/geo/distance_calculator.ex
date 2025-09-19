defmodule OjolMvp.Geo.DistanceCalculator do
  @earth_radius_km 6371.0

  @doc """
  Calculate distance between two points using Haversine formula
  Returns distance in kilometers
  """
  def haversine_distance(lat1, lng1, lat2, lng2) do
    # Convert to float if Decimal
    lat1 = to_float(lat1)
    lng1 = to_float(lng1)
    lat2 = to_float(lat2)
    lng2 = to_float(lng2)

    # Convert degrees to radians
    lat1_rad = deg_to_rad(lat1)
    lng1_rad = deg_to_rad(lng1)
    lat2_rad = deg_to_rad(lat2)
    lng2_rad = deg_to_rad(lng2)

    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlng = lng2_rad - lng1_rad

    a =
      :math.sin(dlat / 2) * :math.sin(dlat / 2) +
        :math.cos(lat1_rad) * :math.cos(lat2_rad) *
          :math.sin(dlng / 2) * :math.sin(dlng / 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))
    distance = @earth_radius_km * c

    Float.round(distance, 2)
  end

  @doc """
  Calculate price based on distance
  Base fare + per-km rate
  """
  def calculate_price(distance_km, base_price \\ 5000, price_per_km \\ 3000) do
    distance = to_float(distance_km)
    total = base_price + distance * price_per_km
    round(total)
  end

  @doc """
  Estimate trip duration based on distance and traffic
  Returns duration in minutes
  """
  def estimate_duration(distance_km, avg_speed_kmh \\ 25) do
    distance = to_float(distance_km)
    duration_hours = distance / avg_speed_kmh
    duration_minutes = duration_hours * 60
    round(duration_minutes)
  end

  defp deg_to_rad(degrees), do: degrees * :math.pi() / 180

  defp to_float(%Decimal{} = decimal), do: Decimal.to_float(decimal)
  defp to_float(value) when is_number(value), do: value
end
