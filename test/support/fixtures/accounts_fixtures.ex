defmodule OjolMvp.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OjolMvp.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        average_rating: "120.5",
        is_available: true,
        latitude: "120.5",
        longitude: "120.5",
        name: "some name",
        phone: "some phone",
        total_ratings: 42,
        type: "some type"
      })
      |> OjolMvp.Accounts.create_user()

    user
  end
end
