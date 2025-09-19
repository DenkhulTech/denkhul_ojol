# test/ojol_mvp/geo/distance_calculator_test.exs
defmodule OjolMvp.Geo.DistanceCalculatorTest do
  use ExUnit.Case, async: true

  alias OjolMvp.Geo.DistanceCalculator

  describe "haversine_distance/4" do
    test "calculates distance between Jakarta and Bandung" do
      # Jakarta coordinates
      jakarta_lat = -6.2088
      jakarta_lng = 106.8456

      # Bandung coordinates
      bandung_lat = -6.9175
      bandung_lng = 107.6191

      distance =
        DistanceCalculator.haversine_distance(
          jakarta_lat,
          jakarta_lng,
          bandung_lat,
          bandung_lng
        )

      # Distance should be approximately 120-140 km
      assert distance >= 120.0
      assert distance <= 140.0
    end

    test "returns 0 for same coordinates" do
      lat = -6.2088
      lng = 106.8456

      distance = DistanceCalculator.haversine_distance(lat, lng, lat, lng)
      assert distance == 0.0
    end

    test "works with Decimal inputs" do
      lat1 = Decimal.new("-6.2088")
      lng1 = Decimal.new("106.8456")
      lat2 = Decimal.new("-6.1944")
      lng2 = Decimal.new("106.8229")

      distance = DistanceCalculator.haversine_distance(lat1, lng1, lat2, lng2)
      assert is_float(distance)
      assert distance > 0
    end

    test "calculates short distance accurately" do
      # Very close coordinates (about 1km apart)
      lat1 = -6.2088
      lng1 = 106.8456
      lat2 = -6.2000
      lng2 = 106.8500

      distance = DistanceCalculator.haversine_distance(lat1, lng1, lat2, lng2)
      # Should be less than 2km
      assert distance < 2.0
      # But more than 500m
      assert distance > 0.5
    end
  end

  describe "calculate_price/3" do
    test "calculates price with default rates" do
      # 10.5 km
      distance = 10.5
      price = DistanceCalculator.calculate_price(distance)

      # Base fare (5000) + distance (10.5 * 3000) = 36,500
      expected = 5000 + 10.5 * 3000
      assert price == round(expected)
    end

    test "calculates price with custom rates" do
      distance = 5.0
      base_price = 7000
      price_per_km = 4000

      price = DistanceCalculator.calculate_price(distance, base_price, price_per_km)
      # 27,000
      expected = 7000 + 5.0 * 4000

      assert price == 27000
    end

    test "handles Decimal distance input" do
      distance = Decimal.new("8.75")
      price = DistanceCalculator.calculate_price(distance)

      expected = 5000 + 8.75 * 3000
      assert price == round(expected)
    end

    test "minimum price is base price for very short distances" do
      # 100m
      distance = 0.1
      price = DistanceCalculator.calculate_price(distance)

      # Should be base price + tiny distance cost
      assert price >= 5000
      assert price < 6000
    end
  end

  describe "estimate_duration/2" do
    test "estimates duration with default speed" do
      # 25 km
      distance = 25.0
      duration = DistanceCalculator.estimate_duration(distance)

      # At 25 km/h = 1 hour = 60 minutes
      assert duration == 60
    end

    test "estimates duration with custom speed" do
      # 30 km
      distance = 30.0
      # 60 km/h
      avg_speed = 60
      duration = DistanceCalculator.estimate_duration(distance, avg_speed)

      # 30km at 60km/h = 0.5 hour = 30 minutes
      assert duration == 30
    end

    test "handles Decimal distance" do
      # 12.5 km
      distance = Decimal.new("12.5")
      duration = DistanceCalculator.estimate_duration(distance)

      # At default 25 km/h = 0.5 hour = 30 minutes
      assert duration == 30
    end

    test "rounds duration to nearest minute" do
      # 10 km
      distance = 10.0
      # 30 km/h
      avg_speed = 30
      duration = DistanceCalculator.estimate_duration(distance, avg_speed)

      # 10/30 * 60 = 20 minutes exactly
      assert duration == 20
    end
  end
end
