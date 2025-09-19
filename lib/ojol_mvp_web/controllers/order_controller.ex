defmodule OjolMvpWeb.OrderController do
  use OjolMvpWeb, :controller

  alias OjolMvp.Orders
  alias OjolMvp.Orders.Order
  alias Guardian.Plug.EnsureAuthenticated
  alias Guardian.Plug.LoadResource

  action_fallback OjolMvpWeb.FallbackController

  # All order actions require authentication
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
          order_params_with_customer = Map.put(order_params, "customer_id", current_user.id)

          with {:ok, %Order{} = order} <- Orders.create_order(order_params_with_customer) do
            IO.puts("=== Order created with status: #{order.status} ===")

            # Broadcast for new order if pending
            if order.status == "pending" do
              IO.puts("=== Broadcasting new order ===")
              OjolMvpWeb.OrderChannel.broadcast_new_order(order)
              IO.puts("=== Broadcast complete ===")
            end

            # Load full order with preloaded associations
            order = Orders.get_order!(order.id) |> OjolMvp.Repo.preload([:customer, :driver])

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
        case Orders.get_order!(order_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Order not found"})

          order ->
            # Preload associations
            order = OjolMvp.Repo.preload(order, [:customer, :driver])

            if can_view_order?(current_user, order) do
              json(conn, %{data: format_order_response(order, current_user)})
            else
              conn
              |> put_status(:forbidden)
              |> json(%{error: "You don't have permission to view this order"})
            end
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
        case Orders.get_order!(order_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Order not found"})

          order ->
            case authorize_order_update(current_user, order) do
              :ok ->
                case validate_update_params(order_params) do
                  :ok ->
                    with {:ok, %Order{} = updated_order} <-
                           Orders.update_order(order, order_params) do
                      updated_order = OjolMvp.Repo.preload(updated_order, [:customer, :driver])

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
        case Orders.get_order!(order_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Order not found"})

          order ->
            case authorize_order_cancellation(current_user, order) do
              :ok ->
                with {:ok, %Order{} = _cancelled_order} <-
                       Orders.update_order(order, %{status: "cancelled"}) do
                  # Notify driver if order was accepted
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
          case Orders.accept_order(id, current_user.id) do
            {:ok, order} ->
              # Broadcast status change to customer
              OjolMvpWeb.Endpoint.broadcast("order:#{order.id}", "status_changed", %{
                status: "accepted",
                driver_id: current_user.id,
                driver_name: current_user.name,
                driver_phone: current_user.phone,
                message: "Driver accepted your order"
              })

              order = Orders.get_order!(order.id) |> OjolMvp.Repo.preload([:customer, :driver])

              json(conn, %{
                data: format_order_response(order, current_user),
                message: "Order accepted successfully"
              })

            {:error, message} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: message})
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
        case Orders.get_order!(id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Order not found"})

          order ->
            case authorize_trip_action(current_user, order, "start") do
              :ok ->
                case Orders.start_trip(id) do
                  {:ok, order} ->
                    # Broadcast status change
                    OjolMvpWeb.Endpoint.broadcast("order:#{order.id}", "status_changed", %{
                      status: "in_progress",
                      message: "Driver has started the trip"
                    })

                    order =
                      Orders.get_order!(order.id) |> OjolMvp.Repo.preload([:customer, :driver])

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
        case Orders.get_order!(id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "Order not found"})

          order ->
            case authorize_trip_action(current_user, order, "complete") do
              :ok ->
                case Orders.complete_trip(id) do
                  {:ok, order} ->
                    # Broadcast completion
                    OjolMvpWeb.Endpoint.broadcast("order:#{order.id}", "status_changed", %{
                      status: "completed",
                      message: "Trip completed successfully"
                    })

                    order =
                      Orders.get_order!(order.id) |> OjolMvp.Repo.preload([:customer, :driver])

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
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid order ID"})
    end
  end

  # Private functions

  defp get_user_orders(user_id, user_type, page, limit, status_filter) do
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
  end

  defp count_user_orders(user_id, user_type, status_filter) do
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
  end

  defp get_available_orders(driver_lat, driver_lng, _radius, page, limit) do
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
      Map.put(
        order,
        :distance_from_driver,
        calculate_distance(driver_lat, driver_lng, order.pickup_lat, order.pickup_lng)
      )
    end)
  end

  defp count_available_orders(_driver_lat, _driver_lng, _radius) do
    import Ecto.Query

    from(o in Order,
      where: o.status == "pending" and is_nil(o.driver_id),
      select: count(o.id)
    )
    |> OjolMvp.Repo.one()
  end

  defp calculate_distance(lat1, lon1, lat2, lon2) do
    {lat1, _} = if is_binary(lat1), do: Float.parse(lat1), else: {lat1, ""}
    {lon1, _} = if is_binary(lon1), do: Float.parse(lon1), else: {lon1, ""}
    {lat2, _} = if is_binary(lat2), do: Float.parse(lat2), else: {lat2, ""}
    {lon2, _} = if is_binary(lon2), do: Float.parse(lon2), else: {lon2, ""}

    r = 6371
    dlat = :math.pi() * (lat2 - lat1) / 180
    dlon = :math.pi() * (lon2 - lon1) / 180

    a =
      :math.sin(dlat / 2) * :math.sin(dlat / 2) +
        :math.cos(:math.pi() * lat1 / 180) * :math.cos(:math.pi() * lat2 / 180) *
          :math.sin(dlon / 2) * :math.sin(dlon / 2)

    c = 2 * :math.asin(:math.sqrt(a))

    Float.round(r * c, 2)
  end

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
    radius = params["radius"] || 10.0

    cond do
      is_nil(lat) or is_nil(lng) ->
        {:error, "Driver latitude and longitude are required"}

      !valid_coordinates?(lat, lng) ->
        {:error, "Invalid driver coordinates"}

      !is_number(radius) or radius <= 0 or radius > 50 ->
        {:error, "Radius must be between 0 and 50 km"}

      true ->
        {:ok, lat, lng, radius}
    end
  end

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
    with {:ok, lat_val} <- parse_float(lat),
         {:ok, lng_val} <- parse_float(lng) do
      lat_val >= -90.0 and lat_val <= 90.0 and lng_val >= -180.0 and lng_val <= 180.0
    else
      _ -> false
    end
  end

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
      price: order.price,
      notes: order.notes,
      customer: if(order.customer, do: format_user_info(order.customer), else: nil),
      driver: if(order.driver, do: format_user_info(order.driver), else: nil),
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
      price: order.price,
      distance_from_driver: Map.get(order, :distance_from_driver, 0.0),
      customer: %{
        name: order.customer.name,
        phone: mask_phone(order.customer.phone)
      },
      created_at: order.inserted_at
    }
  end

  defp format_user_info(user) do
    %{
      id: user.id,
      name: user.name,
      phone: user.phone,
      type: user.type
    }
  end

  defp mask_phone(phone) do
    if String.length(phone) > 6 do
      first_part = String.slice(phone, 0, 3)
      last_part = String.slice(phone, -3, 3)
      first_part <> "****" <> last_part
    else
      phone
    end
  end

  defp notify_order_cancellation(order) do
    if order.driver_id do
      OjolMvpWeb.Endpoint.broadcast("driver:#{order.driver_id}", "order_cancelled", %{
        order_id: order.id,
        message: "Customer has cancelled the order"
      })
    end
  end

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

  defp parse_float(value) when is_float(value), do: {:ok, value}
  defp parse_float(value) when is_integer(value), do: {:ok, value * 1.0}

  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} -> {:ok, float}
      _ -> :error
    end
  end

  defp parse_float(_), do: :error
end
