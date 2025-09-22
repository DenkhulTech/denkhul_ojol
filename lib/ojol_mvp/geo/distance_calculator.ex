defmodule OjolMvp.Geo.DistanceCalculator do
  require Logger
  @earth_radius_km 6371.0

  @doc """
  Calculate distance between two points using Haversine formula
  Returns distance in kilometers
  """
  def haversine_distance(lat1, lng1, lat2, lng2) do
    with {:ok, lat1_f} <- safe_to_float(lat1),
         {:ok, lng1_f} <- safe_to_float(lng1),
         {:ok, lat2_f} <- safe_to_float(lat2),
         {:ok, lng2_f} <- safe_to_float(lng2) do
      # Validate coordinate ranges
      cond do
        not valid_latitude?(lat1_f) or not valid_latitude?(lat2_f) ->
          Logger.error("Invalid latitude values: #{lat1_f}, #{lat2_f}")
          {:error, :invalid_latitude}

        not valid_longitude?(lng1_f) or not valid_longitude?(lng2_f) ->
          Logger.error("Invalid longitude values: #{lng1_f}, #{lng2_f}")
          {:error, :invalid_longitude}

        true ->
          distance = calculate_haversine(lat1_f, lng1_f, lat2_f, lng2_f)
          {:ok, Float.round(distance, 2)}
      end
    else
      {:error, reason} = error ->
        Logger.error("Distance calculation failed: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Calculate price based on distance - returns {:ok, price} or {:error, reason}
  """
  def calculate_price(distance_km, base_price \\ 5000, price_per_km \\ 3000) do
    case safe_to_float(distance_km) do
      {:ok, distance} when distance >= 0 ->
        total = base_price + distance * price_per_km
        {:ok, round(total)}

      {:ok, _negative} ->
        {:error, :negative_distance}

      {:error, reason} ->
        Logger.error("Price calculation failed for distance: #{inspect(distance_km)}")
        {:error, reason}
    end
  end

  @doc """
  Estimate trip duration - returns {:ok, minutes} or {:error, reason}
  """
  def estimate_duration(distance_km, avg_speed_kmh \\ 25) do
    with {:ok, distance} when distance >= 0 <- safe_to_float(distance_km),
         true <- avg_speed_kmh > 0 do
      duration_hours = distance / avg_speed_kmh
      duration_minutes = duration_hours * 60
      {:ok, round(duration_minutes)}
    else
      {:ok, _negative} -> {:error, :negative_distance}
      false -> {:error, :invalid_speed}
      {:error, reason} -> {:error, reason}
    end
  end

  # ===== PRIVATE FUNCTIONS =====

  defp calculate_haversine(lat1, lng1, lat2, lng2) do
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
    @earth_radius_km * c
  end

  defp deg_to_rad(degrees), do: degrees * :math.pi() / 180

  defp valid_latitude?(lat), do: lat >= -90.0 and lat <= 90.0
  defp valid_longitude?(lng), do: lng >= -180.0 and lng <= 180.0

  defp is_finite_float?(value) when is_float(value) do
    # Check for infinity and NaN manually
    # positive infinity check
    # negative infinity check
    # NaN check (NaN != NaN)
    value != :math.pi() + 1.0e308 and
      value != :math.pi() - 1.0e308 and
      value == value
  end

  # Safe conversion to float with comprehensive error handling
  defp safe_to_float(value) do
    case value do
      nil ->
        {:error, :nil_value}

      %Decimal{} = decimal ->
        try do
          float_val = Decimal.to_float(decimal)

          if is_finite_float?(float_val) do
            {:ok, float_val}
          else
            {:error, :infinite_or_nan}
          end
        rescue
          _ -> {:error, :decimal_conversion_failed}
        end

      value when is_float(value) ->
        if is_finite_float?(value) do
          {:ok, value}
        else
          {:error, :infinite_or_nan}
        end

      value when is_integer(value) ->
        {:ok, value * 1.0}

      value when is_binary(value) ->
        case String.trim(value) do
          "" ->
            {:error, :empty_string}

          trimmed_value ->
            case Float.parse(trimmed_value) do
              {num, ""} ->
                if is_finite_float?(num) do
                  {:ok, num}
                else
                  {:error, :infinite_or_nan}
                end

              {_num, remainder} ->
                {:error, {:parse_remainder, remainder}}

              :error ->
                {:error, {:invalid_string, value}}
            end
        end

      value ->
        Logger.error("Unexpected type in safe_to_float: #{inspect(value)} (#{typeof(value)})")
        {:error, {:unsupported_type, typeof(value)}}
    end
  end

  # Helper function untuk logging type
  defp typeof(x) when is_atom(x), do: :atom
  defp typeof(x) when is_binary(x), do: :string
  defp typeof(x) when is_float(x), do: :float
  defp typeof(x) when is_integer(x), do: :integer
  defp typeof(x) when is_list(x), do: :list
  defp typeof(x) when is_map(x), do: :map
  defp typeof(%Decimal{}), do: :decimal
  defp typeof(_), do: :unknown

  # ===== LEGACY SUPPORT =====
  # Untuk backward compatibility dengan kode yang sudah ada
  def to_float(value) do
    case safe_to_float(value) do
      {:ok, float_val} ->
        float_val

      {:error, reason} ->
        Logger.warning(
          "to_float/1 failed for #{inspect(value)}: #{inspect(reason)}, returning 0.0"
        )

        0.0
    end
  end
end
