defmodule OjolMvpWeb.UserController do
  use OjolMvpWeb, :controller

  alias OjolMvp.Accounts
  alias OjolMvp.Accounts.User

  action_fallback OjolMvpWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, %{users: users})
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user.id}")
      |> render(:show, %{user: user})
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, %{user: user})
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, :show, %{user: user})
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
def update_location(conn, %{"id" => user_id, "latitude" => lat, "longitude" => lng}) do
  case Accounts.update_user_location(user_id, lat, lng) do
    {:ok, user} ->
      render(conn, :show, user: user)
    {:error, %Ecto.Changeset{} = changeset} ->
      conn
      |> put_status(:unprocessable_entity)
      |> put_view(json: OjolMvpWeb.ChangesetJSON)
      |> render(:error, changeset: changeset)
  end
end
end
