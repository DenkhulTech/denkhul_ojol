defmodule OjolMvp.Maps.RoutingService do
  @osrm_base_url "http://router.project-osrm.org"

  @doc """
  Get route information from OpenStreetMap OSRM service
  """
  def get_route(pickup_lat, pickup_lng, dest_lat, dest_lng) do
    url = build_osrm_url(pickup_lng, pickup_lat, dest_lng, dest_lat)

    case HTTPoison.get(url, [], timeout: 10_000) do
      {:ok, %{status_code: 200, body: body}} ->
        parse_osrm_response(body)

      {:ok, %{status_code: status}} ->
        {:error, "OSRM API returned status #{status}"}

      {:error, %{reason: reason}} ->
        {:error, "Failed to connect to OSRM: #{reason}"}
    end
  end

  @doc """
  Get multiple route options
  """
  def get_route_alternatives(pickup_lat, pickup_lng, dest_lat, dest_lng) do
    url = build_osrm_url(pickup_lng, pickup_lat, dest_lng, dest_lat, alternatives: true)

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        parse_multiple_routes(body)

      error ->
        {:error, error}
    end
  end

  defp build_osrm_url(lng1, lat1, lng2, lat2, opts \\ []) do
    base_params = "geometries=geojson&overview=full"
    alternatives = if opts[:alternatives], do: "&alternatives=true", else: ""

    "#{@osrm_base_url}/route/v1/driving/#{lng1},#{lat1};#{lng2},#{lat2}?#{base_params}#{alternatives}"
  end

  defp parse_osrm_response(body) do
    case Jason.decode(body) do
      {:ok, %{"routes" => [route | _], "code" => "Ok"}} ->
        {:ok,
         %{
           distance_km: route["distance"] / 1000,
           duration_min: route["duration"] / 60,
           geometry: route["geometry"],
           steps: extract_steps(route)
         }}

      {:ok, %{"code" => error_code}} ->
        {:error, "OSRM error: #{error_code}"}

      {:error, _} ->
        {:error, "Failed to parse OSRM response"}
    end
  end

  defp parse_multiple_routes(body) do
    case Jason.decode(body) do
      {:ok, %{"routes" => routes, "code" => "Ok"}} ->
        parsed_routes =
          Enum.map(routes, fn route ->
            %{
              distance_km: route["distance"] / 1000,
              duration_min: route["duration"] / 60,
              geometry: route["geometry"]
            }
          end)

        {:ok, parsed_routes}

      error ->
        {:error, error}
    end
  end

  defp extract_steps(route) do
    case route["legs"] do
      [%{"steps" => steps} | _] ->
        Enum.map(steps, fn step ->
          %{
            instruction: step["maneuver"]["instruction"] || "Continue",
            distance_m: step["distance"],
            duration_s: step["duration"]
          }
        end)

      _ ->
        []
    end
  end
end
