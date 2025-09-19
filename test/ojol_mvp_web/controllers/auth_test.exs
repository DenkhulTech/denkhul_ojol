# test/ojol_mvp_web/controllers/user_controller_test.exs
defmodule OjolMvpWeb.UserControllerTest do
  use OjolMvpWeb.ConnCase, async: true

  describe "POST /api/users (registration)" do
    test "creates customer with valid data", %{conn: conn} do
      user_params = %{
        name: "Test Customer",
        phone: "+6281234567890",
        type: "customer",
        password: "password123"
      }

      conn = post(conn, ~p"/api/users", user: user_params)

      assert %{"data" => user_data, "message" => message} = json_response(conn, 201)
      assert user_data["name"] == "Test Customer"
      assert user_data["phone"] == "+6281234567890"
      assert user_data["type"] == "customer"
      assert message == "User created successfully"
      refute Map.has_key?(user_data, "password")
      refute Map.has_key?(user_data, "password_hash")
    end

    test "creates driver with valid data", %{conn: conn} do
      user_params = %{
        name: "Test Driver",
        phone: "+6281234567891",
        type: "driver",
        password: "password123"
      }

      conn = post(conn, ~p"/api/users", user: user_params)

      assert %{"data" => user_data} = json_response(conn, 201)
      assert user_data["type"] == "driver"
    end

    test "rejects registration with missing fields", %{conn: conn} do
      user_params = %{
        name: "Test User"
        # Missing phone, type, password
      }

      conn = post(conn, ~p"/api/users", user: user_params)

      assert %{"error" => error} = json_response(conn, 400)
      assert error =~ "Missing required fields"
    end

    test "rejects registration with invalid phone", %{conn: conn} do
      user_params = %{
        name: "Test User",
        phone: "invalid-phone",
        type: "customer",
        password: "password123"
      }

      conn = post(conn, ~p"/api/users", user: user_params)

      assert %{"error" => error} = json_response(conn, 400)
      assert error =~ "Invalid phone number format"
    end

    test "rejects registration with invalid type", %{conn: conn} do
      user_params = %{
        name: "Test User",
        phone: "+6281234567890",
        type: "admin",
        password: "password123"
      }

      conn = post(conn, ~p"/api/users", user: user_params)

      assert %{"error" => error} = json_response(conn, 400)
      assert error =~ "Type must be either 'customer' or 'driver'"
    end

    test "rejects registration with short password", %{conn: conn} do
      user_params = %{
        name: "Test User",
        phone: "+6281234567890",
        type: "customer",
        password: "123"
      }

      conn = post(conn, ~p"/api/users", user: user_params)

      assert %{"error" => error} = json_response(conn, 400)
      assert error =~ "Password must be at least 8 characters long"
    end
  end

  describe "POST /api/auth/register" do
    test "registers customer with valid data", %{conn: conn} do
      user_params = %{
        name: "Test Customer",
        phone: "+6281234567890",
        type: "customer",
        password: "password123"
      }

      conn = post(conn, ~p"/api/auth/register", user: user_params)

      assert %{
               "message" => "User created successfully",
               "token" => token,
               "user" => user_data
             } = json_response(conn, 201)

      assert is_binary(token)
      assert user_data["name"] == "Test Customer"
      assert user_data["phone"] == "+6281234567890"
      assert user_data["type"] == "customer"
      refute Map.has_key?(user_data, "password")
    end

    test "registers driver with valid data", %{conn: conn} do
      user_params = %{
        name: "Test Driver",
        phone: "+6281234567891",
        type: "driver",
        password: "password123"
      }

      conn = post(conn, ~p"/api/auth/register", user: user_params)

      assert %{"user" => user_data} = json_response(conn, 201)
      assert user_data["type"] == "driver"
    end

    test "rejects registration with invalid data", %{conn: conn} do
      user_params = %{
        name: "Test",
        phone: "invalid",
        type: "admin",
        password: "123"
      }

      conn = post(conn, ~p"/api/auth/register", user: user_params)

      assert %{"errors" => errors} = json_response(conn, 422)
      assert is_map(errors)
    end
  end

  describe "POST /api/auth/login" do
    setup do
      # Create a test user first
      user_params = %{
        name: "Test User",
        phone: "+6281234567890",
        type: "customer",
        password: "password123"
      }

      {:ok, user} = Accounts.create_user(user_params)
      {:ok, user: user}
    end

    test "logs in with valid credentials", %{conn: conn, user: user} do
      login_params = %{
        phone: user.phone,
        password: "password123"
      }

      conn = post(conn, ~p"/api/auth/login", login_params)

      assert %{
               "message" => "Login successful",
               "token" => token,
               "user" => user_data
             } = json_response(conn, 200)

      assert is_binary(token)
      assert user_data["id"] == user.id
      assert user_data["phone"] == user.phone
      assert user_data["type"] == user.type
      refute Map.has_key?(user_data, "password")
    end

    test "rejects login with invalid phone", %{conn: conn} do
      login_params = %{
        phone: "+6281234567999",
        password: "password123"
      }

      conn = post(conn, ~p"/api/auth/login", login_params)

      assert %{"error" => "Invalid phone or password"} = json_response(conn, 401)
    end

    test "rejects login with invalid password", %{conn: conn, user: user} do
      login_params = %{
        phone: user.phone,
        password: "wrongpassword"
      }

      conn = post(conn, ~p"/api/auth/login", login_params)

      assert %{"error" => "Invalid phone or password"} = json_response(conn, 401)
    end

    test "rejects login with missing parameters", %{conn: conn} do
      # Missing password
      conn = post(conn, ~p"/api/auth/login", %{phone: "+6281234567890"})

      # Bad request or pattern match error
      assert response(conn, 400)
    end
  end

  describe "POST /api/auth/refresh" do
    setup do
      user_params = %{
        name: "Test User",
        phone: "+6281234567890",
        type: "customer",
        password: "password123"
      }

      {:ok, user} = Accounts.create_user(user_params)
      {:ok, token, _claims} = OjolMvp.Guardian.encode_and_sign(user)

      {:ok, user: user, token: token}
    end

    test "refreshes token with valid authentication", %{conn: conn, token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/auth/refresh")

      assert %{"token" => new_token} = json_response(conn, 200)
      assert is_binary(new_token)
      # Should be a new token
      assert new_token != token
    end

    test "rejects refresh without authentication", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/refresh")

      # Should return 401 or 403
      assert response(conn, 401) || response(conn, 403)
    end
  end
end
