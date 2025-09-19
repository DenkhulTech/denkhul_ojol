defmodule OjolMvpWeb.UserJSON do
  alias OjolMvp.Accounts.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      name: user.name,
      phone: user.phone,
      type: user.type,
      latitude: safe_decimal(user.latitude),
      longitude: safe_decimal(user.longitude),
      is_available: user.is_available,
      average_rating: safe_decimal(user.average_rating),
      total_ratings: user.total_ratings
    }
  end

  defp safe_decimal(nil), do: nil
  defp safe_decimal(%Decimal{} = dec), do: Decimal.to_float(dec)
  defp safe_decimal(val), do: val
end
