defmodule OjolMvpWeb.AuthController do
  use OjolMvpWeb, :controller
  alias OjolMvp.{Accounts, Guardian}

  def register(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)

        conn
        |> put_status(:created)
        |> json(%{
          message: "User created successfully",
          token: token,
          user: %{
            id: user.id,
            name: user.name,
            phone: user.phone,
            type: user.type
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def login(conn, %{"phone" => phone, "password" => password}) do
    case Accounts.authenticate_user(phone, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)

        json(conn, %{
          message: "Login successful",
          token: token,
          user: %{
            id: user.id,
            name: user.name,
            phone: user.phone,
            type: user.type,
            is_available: user.is_available
          }
        })

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid phone or password"})
    end
  end

  def refresh(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    {:ok, new_token, _claims} = Guardian.encode_and_sign(user)

    json(conn, %{token: new_token})
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
