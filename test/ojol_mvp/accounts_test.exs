defmodule OjolMvp.AccountsTest do
  use OjolMvp.DataCase

  alias OjolMvp.Accounts

  describe "users" do
    alias OjolMvp.Accounts.User

    import OjolMvp.AccountsFixtures

    @invalid_attrs %{
      name: nil,
      type: nil,
      phone: nil,
      latitude: nil,
      longitude: nil,
      is_available: nil,
      average_rating: nil,
      total_ratings: nil
    }

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{
        name: "some name",
        type: "some type",
        phone: "some phone",
        latitude: "120.5",
        longitude: "120.5",
        is_available: true,
        average_rating: "120.5",
        total_ratings: 42
      }

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.name == "some name"
      assert user.type == "some type"
      assert user.phone == "some phone"
      assert user.latitude == Decimal.new("120.5")
      assert user.longitude == Decimal.new("120.5")
      assert user.is_available == true
      assert user.average_rating == Decimal.new("120.5")
      assert user.total_ratings == 42
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()

      update_attrs = %{
        name: "some updated name",
        type: "some updated type",
        phone: "some updated phone",
        latitude: "456.7",
        longitude: "456.7",
        is_available: false,
        average_rating: "456.7",
        total_ratings: 43
      }

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.name == "some updated name"
      assert user.type == "some updated type"
      assert user.phone == "some updated phone"
      assert user.latitude == Decimal.new("456.7")
      assert user.longitude == Decimal.new("456.7")
      assert user.is_available == false
      assert user.average_rating == Decimal.new("456.7")
      assert user.total_ratings == 43
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
