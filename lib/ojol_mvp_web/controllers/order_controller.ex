defmodule OjolMvpWeb.OrderController do
  use OjolMvpWeb, :controller
  require Logger

  alias OjolMvp.Orders
  alias OjolMvp.Orders.Order
  alias OjolMvp.Geo.DistanceCalculator
  alias OjolMvp.Maps.RoutingService
  alias Guardian.Plug.EnsureAuthenticated
  alias Guardian.Plug.LoadResource

  action_fallback OjolMvpWeb.FallbackController

  plug EnsureAuthenticated
  plug LoadResource

  @doc """
  Create new order - only customers can create orders
  """
  def create(conn, %{"order" => order_params}) do
    current_user = Guardian.Plug.current_resource(conn)

    if current_user.type != "customer" do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only customers can create orders"})
    else
      case validate_order_params(order_params) do
        :ok ->
          # Calculate distance, price, and duration
          enhanced_params = enhance_order_params(order_params, current_user.id)

          with {:ok, %Order{} = order} <- Orders.create_order(enhanced_params) do
            IO.puts("=== Order created with status: #{order.status} ===")

            if order.status == "pending" do
              IO.puts("=== Broadcasting new order ===")
              OjolMvpWeb.OrderChannel.broadcast_new_order(order)
              IO.puts("=== Broadcast complete ===")
            end

            order = safe_get_order_with_preload(order.id)

            conn
            |> put_status(:created)
            |> put_resp_header("location", ~p"/api/orders/#{order.id}")
            |> json(%{
              data: format_order_response(order, current_user),
              message: "Order created successfully"
            })
          end

        {:error, message} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: message})
      end
    end
  end

  @doc """
  Show specific order - only participants can view
  """
  def show(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(id) do
      {:ok, order_id} ->
        try do
          order = Orders.get_order!(order_id)
          order = safe_preload(order, [:customer, :driver])

          if can_view_order?(current_user, order) do
            json(conn, %{data: format_order_response(order, current_user)})
          else
            conn
            |> put_status(:forbidden)
            |> json(%{error: "You don't have permission to view this order"})
          end
        rescue
          Ecto.NoResultsError ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Order not found"})
        catch
          error ->
            Logger.error("Error in show: #{inspect(error)}")

            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Internal server error"})
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid order ID"})
    end
  end

  @doc """
  Update order - only customers can update pending orders
  """
  def update(conn, %{"id" => id, "order" => order_params}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(id) do
      {:ok, order_id} ->
        try do
          order = Orders.get_order!(order_id)

          case authorize_order_update(current_user, order) do
            :ok ->
              case validate_update_params(order_params) do
                :ok ->
                  with {:ok, %Order{} = updated_order} <-
                         Orders.update_order(order, order_params) do
                    updated_order = safe_preload(updated_order, [:customer, :driver])

                    json(conn, %{
                      data: format_order_response(updated_order, current_user),
                      message: "Order updated successfully"
                    })
                  end

                {:error, message} ->
                  conn
                  |> put_status(:bad_request)
                  |> json(%{error: message})
              end

            {:error, message} ->
              conn
              |> put_status(:forbidden)
              |> json(%{error: message})
          end
        rescue
          Ecto.NoResultsError ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Order not found"})
        catch
          error ->
            Logger.error("Error in update: #{inspect(error)}")

            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Internal server error"})
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid order ID"})
    end
  end

  @doc """
  Cancel/Delete order - only customers can cancel pending orders
  """
  def delete(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(id) do
      {:ok, order_id} ->
        try do
          order = Orders.get_order!(order_id)

          case authorize_order_cancellation(current_user, order) do
            :ok ->
              with {:ok, %Order{} = _cancelled_order} <-
                     Orders.update_order(order, %{status: "cancelled"}) do
                if order.driver_id do
                  notify_order_cancellation(order)
                end

                json(conn, %{message: "Order cancelled successfully"})
              end

            {:error, message} ->
              conn
              |> put_status(:forbidden)
              |> json(%{error: message})
          end
        rescue
          Ecto.NoResultsError ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Order not found"})
        catch
          error ->
            Logger.error("Error in delete: #{inspect(error)}")

            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Internal server error"})
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid order ID"})
    end
  end

  @doc """
  Get current user's orders with filtering
  """
  def my_orders(conn, params) do
    try do
      current_user = Guardian.Plug.current_resource(conn)

      {page, limit} = parse_pagination_params(params)
      status_filter = params["status"]

      orders = get_user_orders(current_user.id, current_user.type, page, limit, status_filter)
      total_count = count_user_orders(current_user.id, current_user.type, status_filter)

      json(conn, %{
        data: Enum.map(orders, &format_order_response(&1, current_user)),
        pagination: %{
          page: page,
          limit: limit,
          total_count: total_count,
          total_pages: ceil(total_count / limit)
        }
      })
    catch
      error ->
        Logger.error("Error in my_orders: #{inspect(error)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Internal server error"})
    end
  end

  @doc """
  Get available orders for drivers with location filtering
  """
  def available_orders(conn, params) do
    current_user = Guardian.Plug.current_resource(conn)

    if current_user.type != "driver" do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only drivers can view available orders"})
    else
      case validate_location_params(params) do
        {:ok, driver_lat, driver_lng, radius} ->
          try do
            {page, limit} = parse_pagination_params(params)

            orders = get_available_orders(driver_lat, driver_lng, radius, page, limit)
            total_count = count_available_orders(driver_lat, driver_lng, radius)

            json(conn, %{
              data: Enum.map(orders, &format_available_order_response/1),
              pagination: %{
                page: page,
                limit: limit,
                total_count: total_count,
                total_pages: ceil(total_count / limit)
              }
            })
          catch
            error ->
              Logger.error("Error in available_orders: #{inspect(error)}")

              conn
              |> put_status(:internal_server_error)
              |> json(%{error: "Internal server error"})
          end

        {:error, message} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: message})
      end
    end
  end

  @doc """
  Accept order - only drivers can accept pending orders
  """
  def accept(conn, %{"id" => order_id}) do
    current_user = Guardian.Plug.current_resource(conn)

    if current_user.type != "driver" do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only drivers can accept orders"})
    else
      case parse_integer(order_id) do
        {:ok, id} ->
          try do
            case safe_accept_order(id, current_user.id) do
              {:ok, order} ->
                safe_broadcast_status_change("order:#{order.id}", %{
                  status: "accepted",
                  driver_id: current_user.id,
                  driver_name: current_user.name,
                  driver_phone: current_user.phone,
                  message: "Driver accepted your order"
                })

                order = safe_get_order_with_preload(order.id)

                json(conn, %{
                  data: format_order_response(order, current_user),
                  message: "Order accepted successfully"
                })

              {:error, message} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{error: message})
            end
          catch
            error ->
              Logger.error("Error in accept: #{inspect(error)}")

              conn
              |> put_status(:internal_server_error)
              |> json(%{error: "Internal server error"})
          end

        :error ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Invalid order ID"})
      end
    end
  end

  @doc """
  Start trip - only assigned driver can start accepted orders
  """
  def start_trip(conn, %{"id" => order_id}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(order_id) do
      {:ok, id} ->
        try do
          order = Orders.get_order!(id)

          case authorize_trip_action(current_user, order, "start") do
            :ok ->
              case safe_start_trip(id) do
                {:ok, order} ->
                  safe_broadcast_status_change("order:#{order.id}", %{
                    status: "in_progress",
                    message: "Driver has started the trip"
                  })

                  order = safe_get_order_with_preload(order.id)

                  json(conn, %{
                    data: format_order_response(order, current_user),
                    message: "Trip started successfully"
                  })

                {:error, message} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> json(%{error: message})
              end

            {:error, message} ->
              conn
              |> put_status(:forbidden)
              |> json(%{error: message})
          end
        rescue
          Ecto.NoResultsError ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Order not found"})
        catch
          error ->
            Logger.error("Error in start_trip: #{inspect(error)}")

            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Internal server error"})
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid order ID"})
    end
  end

  @doc """
  Complete trip - only assigned driver can complete in-progress orders
  """
  def complete(conn, %{"id" => order_id}) do
    current_user = Guardian.Plug.current_resource(conn)

    case parse_integer(order_id) do
      {:ok, id} ->
        try do
          order = Orders.get_order!(id)

          case authorize_trip_action(current_user, order, "complete") do
            :ok ->
              case safe_complete_trip(id) do
                {:ok, order} ->
                  safe_broadcast_status_change("order:#{order.id}", %{
                    status: "completed",
                    message: "Trip completed successfully"
                  })

                  order = safe_get_order_with_preload(order.id)

                  json(conn, %{
                    data: format_order_response(order, current_user),
                    message: "Trip completed successfully"
                  })

                {:error, message} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> json(%{error: message})
              end

            {:error, message} ->
              conn
              |> put_status(:forbidden)
              |> json(%{error: message})
          end
        rescue
          Ecto.NoResultsError ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Order not found"})
        catch
          error ->
            Logger.error("Error in complete: #{inspect(error)}")

            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Internal server error"})
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid order ID"})
    end
  end

  # Safe helper functions
  defp safe_get_order_with_preload(order_id) do
    try do
      Orders.get_order!(order_id) |> safe_preload([:customer, :driver])
    rescue
      error ->
        Logger.error("Error loading order: #{inspect(error)}")
        # Return minimal order structure to prevent crash
        %{id: order_id, status: "unknown"}
    end
  end

  defp safe_preload(order, associations) do
    try do
      OjolMvp.Repo.preload(order, associations)
    rescue
      error ->
        Logger.error("Error preloading: #{inspect(error)}")
        order
    end
  end

  defp safe_accept_order(order_id, driver_id) do
    try do
      Orders.accept_order(order_id, driver_id)
    rescue
      error ->
        Logger.error("Error accepting order: #{inspect(error)}")
        {:error, "Failed to accept order"}
    end
  end

  defp safe_start_trip(order_id) do
    try do
      Orders.start_trip(order_id)
    rescue
      error ->
        Logger.error("Error starting trip: #{inspect(error)}")
        {:error, "Failed to start trip"}
    end
  end

  defp safe_complete_trip(order_id) do
    try do
      Orders.complete_trip(order_id)
    rescue
      error ->
        Logger.error("Error completing trip: #{inspect(error)}")
        {:error, "Failed to complete trip"}
    end
  end

  defp safe_broadcast_status_change(channel, payload) do
    try do
      OjolMvpWeb.Endpoint.broadcast(channel, "status_changed", payload)
    rescue
      error ->
        Logger.error("Broadcast failed: #{inspect(error)}")
        :ok
    end
  end

  # Private query functions
  defp get_user_orders(user_id, user_type, page, limit, status_filter) do
    try do
      import Ecto.Query

      query =
        from o in Order,
          where:
            (^user_type == "customer" and o.customer_id == ^user_id) or
              (^user_type == "driver" and o.driver_id == ^user_id),
          preload: [:customer, :driver],
          order_by: [desc: o.inserted_at],
          limit: ^limit,
          offset: ^((page - 1) * limit)

      query =
        if status_filter do
          from o in query, where: o.status == ^status_filter
        else
          query
        end

      OjolMvp.Repo.all(query)
    rescue
      error ->
        Logger.error("Error getting user orders: #{inspect(error)}")
        []
    end
  end

  defp count_user_orders(user_id, user_type, status_filter) do
    try do
      import Ecto.Query

      query =
        from o in Order,
          where:
            (^user_type == "customer" and o.customer_id == ^user_id) or
              (^user_type == "driver" and o.driver_id == ^user_id),
          select: count(o.id)

      query =
        if status_filter do
          from o in query, where: o.status == ^status_filter
        else
          query
        end

      OjolMvp.Repo.one(query)
    rescue
      error ->
        Logger.error("Error counting user orders: #{inspect(error)}")
        0
    end
  end

  defp get_available_orders(driver_lat, driver_lng, radius, page, limit) do
    try do
      import Ecto.Query

      from(o in Order,
        where: o.status == "pending" and is_nil(o.driver_id),
        preload: [:customer],
        order_by: [desc: o.inserted_at],
        limit: ^limit,
        offset: ^((page - 1) * limit)
      )
      |> OjolMvp.Repo.all()
      |> Enum.map(fn order ->
        distance =
          case DistanceCalculator.haversine_distance(
                 driver_lat,
                 driver_lng,
                 order.pickup_lat,
                 order.pickup_lng
               ) do
            {:ok, dist} -> dist
            # nilai tinggi agar di-filter out
            {:error, _} -> 999.0
          end

        Map.put(order, :distance_from_driver, distance)
      end)
      |> Enum.filter(fn order -> order.distance_from_driver <= radius end)
    rescue
      error ->
        Logger.error("Error getting available orders: #{inspect(error)}")
        []
    end
  end

  defp count_available_orders(driver_lat, driver_lng, radius) do
    try do
      import Ecto.Query

      # Get all pending orders and filter by radius
      orders =
        from(o in Order,
          where: o.status == "pending" and is_nil(o.driver_id),
          select: %{id: o.id, pickup_lat: o.pickup_lat, pickup_lng: o.pickup_lng}
        )
        |> OjolMvp.Repo.all()
        |> Enum.filter(fn order ->
          distance =
            case DistanceCalculator.haversine_distance(
                   driver_lat,
                   driver_lng,
                   order.pickup_lat,
                   order.pickup_lng
                 ) do
              {:ok, dist} -> dist
              # nilai tinggi agar di-filter out
              {:error, _} -> 999.0
            end

          distance <= radius
        end)

      length(orders)
    rescue
      error ->
        Logger.error("Error counting available orders: #{inspect(error)}")
        0
    end
  end

  # Validation functions
  defp validate_order_params(params) do
    required_fields = [
      "pickup_address",
      "destination_address",
      "pickup_lat",
      "pickup_lng",
      "destination_lat",
      "destination_lng"
    ]

    cond do
      !is_map(params) ->
        {:error, "Invalid order data format"}

      Enum.any?(required_fields, &(is_nil(params[&1]) or params[&1] == "")) ->
        {:error, "Missing required fields: #{Enum.join(required_fields, ", ")}"}

      !valid_coordinates?(params["pickup_lat"], params["pickup_lng"]) ->
        {:error, "Invalid pickup coordinates"}

      !valid_coordinates?(params["destination_lat"], params["destination_lng"]) ->
        {:error, "Invalid destination coordinates"}

      params["price"] && (!is_number(params["price"]) or params["price"] < 0) ->
        {:error, "Price must be a positive number"}

      String.length(params["pickup_address"]) < 5 ->
        {:error, "Pickup address must be at least 5 characters"}

      String.length(params["destination_address"]) < 5 ->
        {:error, "Destination address must be at least 5 characters"}

      true ->
        :ok
    end
  end

  defp validate_update_params(params) do
    cond do
      !is_map(params) ->
        {:error, "Invalid order data format"}

      params["pickup_lat"] && params["pickup_lng"] &&
          !valid_coordinates?(params["pickup_lat"], params["pickup_lng"]) ->
        {:error, "Invalid pickup coordinates"}

      params["destination_lat"] && params["destination_lng"] &&
          !valid_coordinates?(params["destination_lat"], params["destination_lng"]) ->
        {:error, "Invalid destination coordinates"}

      params["price"] && (!is_number(params["price"]) or params["price"] < 0) ->
        {:error, "Price must be a positive number"}

      params["pickup_address"] && String.length(params["pickup_address"]) < 5 ->
        {:error, "Pickup address must be at least 5 characters"}

      params["destination_address"] && String.length(params["destination_address"]) < 5 ->
        {:error, "Destination address must be at least 5 characters"}

      true ->
        :ok
    end
  end

  defp validate_location_params(params) do
    lat = params["lat"]
    lng = params["lng"]
    radius_param = params["radius"] || "10.0"

    # Debug logging (hapus __struct__)
    Logger.info("Raw params: #{inspect(params)}")
    Logger.info("Radius param: #{inspect(radius_param)}")

    # Parse radius
    radius =
      case radius_param do
        nil ->
          10.0

        param when is_binary(param) ->
          case Float.parse(param) do
            {num, ""} -> num
            _ -> 10.0
          end

        param when is_number(param) ->
          param * 1.0

        _ ->
          10.0
      end

    Logger.info("Parsed radius: #{inspect(radius)}")

    cond do
      is_nil(lat) or is_nil(lng) ->
        {:error, "Driver latitude and longitude are required"}

      !valid_coordinates?(lat, lng) ->
        {:error, "Invalid driver coordinates"}

      radius <= 0 or radius > 50 ->
        # Hapus __struct__
        Logger.error("Radius validation failed: #{radius}")
        {:error, "Radius must be between 0 and 50 km"}

      true ->
        {:ok, lat, lng, radius}
    end
  end

  # Authorization functions
  defp authorize_order_update(current_user, order) do
    cond do
      current_user.id != order.customer_id ->
        {:error, "Only the customer who created the order can update it"}

      order.status != "pending" ->
        {:error, "Only pending orders can be updated"}

      true ->
        :ok
    end
  end

  # Enhanced order creation with routing and distance calculation
  defp enhance_order_params(order_params, customer_id) do
    try do
      pickup_lat = DistanceCalculator.to_float(order_params["pickup_lat"])
      pickup_lng = DistanceCalculator.to_float(order_params["pickup_lng"])
      dest_lat = DistanceCalculator.to_float(order_params["destination_lat"])
      dest_lng = DistanceCalculator.to_float(order_params["destination_lng"])

      # Try OSRM first, fallback to Haversine
      case RoutingService.get_route(pickup_lat, pickup_lng, dest_lat, dest_lng) do
        {:ok, route_info} ->
          case DistanceCalculator.calculate_price(route_info.distance_km) do
            {:ok, price} ->
              Map.merge(order_params, %{
                "customer_id" => customer_id,
                "distance_km" => route_info.distance_km,
                "estimated_duration" => round(route_info.duration_min),
                "total_fare" => price
              })

            {:error, _} ->
              Map.merge(order_params, %{
                "customer_id" => customer_id,
                "distance_km" => route_info.distance_km,
                "estimated_duration" => round(route_info.duration_min),
                # fallback price
                "total_fare" => 5000
              })
          end

        {:error, _} ->
          case DistanceCalculator.haversine_distance(pickup_lat, pickup_lng, dest_lat, dest_lng) do
            {:ok, distance} ->
              case DistanceCalculator.calculate_price(distance) do
                {:ok, price} ->
                  Map.merge(order_params, %{
                    "customer_id" => customer_id,
                    "distance_km" => distance,
                    "total_fare" => price
                  })

                {:error, _} ->
                  Map.merge(order_params, %{
                    "customer_id" => customer_id,
                    "distance_km" => distance,
                    # fallback price
                    "total_fare" => 5000
                  })
              end

            {:error, _} ->
              Map.put(order_params, "customer_id", customer_id)
          end
      end
    rescue
      _ -> Map.put(order_params, "customer_id", customer_id)
    end
  end

  defp authorize_order_cancellation(current_user, order) do
    cond do
      current_user.id != order.customer_id ->
        {:error, "Only the customer who created the order can cancel it"}

      order.status in ["completed", "cancelled"] ->
        {:error, "Cannot cancel completed or already cancelled orders"}

      order.status == "in_progress" ->
        {:error, "Cannot cancel orders that are in progress"}

      true ->
        :ok
    end
  end

  defp authorize_trip_action(current_user, order, action) do
    cond do
      current_user.type != "driver" ->
        {:error, "Only drivers can #{action} trips"}

      order.driver_id != current_user.id ->
        {:error, "You can only #{action} orders assigned to you"}

      action == "start" and order.status != "accepted" ->
        {:error, "Can only start accepted orders"}

      action == "complete" and order.status != "in_progress" ->
        {:error, "Can only complete orders that are in progress"}

      true ->
        :ok
    end
  end

  defp can_view_order?(current_user, order) do
    current_user.id == order.customer_id or current_user.id == order.driver_id
  end

  defp valid_coordinates?(lat, lng) do
    try do
      case {DistanceCalculator.to_float(lat), DistanceCalculator.to_float(lng)} do
        {lat_val, lng_val}
        when lat_val >= -90.0 and lat_val <= 90.0 and
               lng_val >= -180.0 and lng_val <= 180.0 ->
          # Extra check: make sure it's not fallback 0.0 for clearly invalid input
          not (lat_val == 0.0 and lng_val == 0.0 and
                 is_binary(lat) and is_binary(lng) and
                 String.trim(lat) not in ["0", "0.0"] and
                 String.trim(lng) not in ["0", "0.0"])

        _ ->
          false
      end
    rescue
      _ -> false
    end
  end

  # Response formatting functions
  defp format_order_response(order, current_user) do
    %{
      id: order.id,
      status: order.status,
      pickup_address: order.pickup_address,
      destination_address: order.destination_address,
      pickup_lat: order.pickup_lat,
      pickup_lng: order.pickup_lng,
      destination_lat: order.destination_lat,
      destination_lng: order.destination_lng,
      distance_km: order.distance_km,
      estimated_duration: order.estimated_duration,
      price: safe_get_price(order),
      total_fare: safe_get_price(order),
      route_geometry: Map.get(order, :route_geometry),
      notes: order.notes,
      customer: safe_format_user_info(order.customer),
      driver: safe_format_user_info(order.driver),
      is_my_order: current_user.id == order.customer_id,
      is_assigned_to_me: current_user.id == order.driver_id,
      created_at: order.inserted_at,
      updated_at: order.updated_at
    }
  end

  defp format_available_order_response(order) do
    %{
      id: order.id,
      pickup_address: order.pickup_address,
      destination_address: order.destination_address,
      pickup_lat: order.pickup_lat,
      pickup_lng: order.pickup_lng,
      destination_lat: order.destination_lat,
      destination_lng: order.destination_lng,
      distance_km: order.distance_km,
      estimated_duration: order.estimated_duration,
      price: safe_get_price(order),
      total_fare: safe_get_price(order),
      distance_from_driver: Map.get(order, :distance_from_driver, 0.0),
      customer: safe_format_customer_info(order.customer),
      created_at: order.inserted_at
    }
  end

  defp safe_get_price(order) do
    cond do
      Map.has_key?(order, :total_fare) and not is_nil(order.total_fare) -> order.total_fare
      Map.has_key?(order, :price) and not is_nil(order.price) -> order.price
      true -> 0
    end
  end

  defp safe_format_user_info(nil), do: nil

  defp safe_format_user_info(user) do
    try do
      %{
        id: user.id,
        name: user.name,
        phone: user.phone,
        type: user.type
      }
    rescue
      _ -> nil
    end
  end

  defp safe_format_customer_info(nil), do: nil

  defp safe_format_customer_info(user) do
    try do
      %{
        name: user.name,
        phone: mask_phone(user.phone)
      }
    rescue
      _ -> nil
    end
  end

  defp mask_phone(phone) when is_binary(phone) do
    if String.length(phone) > 6 do
      first_part = String.slice(phone, 0, 3)
      last_part = String.slice(phone, -3, 3)
      first_part <> "****" <> last_part
    else
      phone
    end
  end

  defp mask_phone(_), do: "****"

  defp notify_order_cancellation(order) do
    try do
      if order.driver_id do
        OjolMvpWeb.Endpoint.broadcast("driver:#{order.driver_id}", "order_cancelled", %{
          order_id: order.id,
          message: "Customer has cancelled the order"
        })
      end
    rescue
      error ->
        Logger.error("Failed to notify cancellation: #{inspect(error)}")
        :ok
    end
  end

  # Utility functions
  defp parse_pagination_params(params) do
    page = params["page"] |> parse_positive_integer(1)
    limit = params["limit"] |> parse_positive_integer(10) |> min(50)
    {page, limit}
  end

  defp parse_positive_integer(nil, default), do: default
  defp parse_positive_integer(value, _default) when is_integer(value) and value > 0, do: value

  defp parse_positive_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} when int > 0 -> int
      _ -> default
    end
  end

  defp parse_positive_integer(_, default), do: default

  defp parse_integer(value) when is_integer(value), do: {:ok, value}

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  defp parse_integer(_), do: :error
end
