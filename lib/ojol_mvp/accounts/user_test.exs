# test/ojol_mvp/accounts/user_test.exs
defmodule OjolMvp.Accounts.UserTest do
  use OjolMvp.DataCase, async: true

  alias OjolMvp.Accounts.User

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{
        name: "John Doe",
        phone: "+6281234567890",
        type: "customer",
        password: "password123"
      }

      changeset = User.changeset(%User{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset with missing required fields" do
      changeset = User.changeset(%User{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset)[:name]
      assert "can't be blank" in errors_on(changeset)[:phone]
      assert "can't be blank" in errors_on(changeset)[:type]
    end

    test "validates name length" do
      # Too short
      changeset = User.changeset(%User{}, %{name: "A", phone: "+6281234567890", type: "customer"})
      assert "should be at least 2 character(s)" in errors_on(changeset)[:name]

      # Too long
      long_name = String.duplicate("a", 51)

      changeset =
        User.changeset(%User{}, %{name: long_name, phone: "+6281234567890", type: "customer"})

      assert "should be at most 50 character(s)" in errors_on(changeset)[:name]
    end

    test "validates password length" do
      # Too short
      attrs = %{name: "John", phone: "+6281234567890", type: "customer", password: "123"}
      changeset = User.changeset(%User{}, attrs)
      assert "should be at least 6 character(s)" in errors_on(changeset)[:password]

      # Too long
      long_password = String.duplicate("a", 129)
      attrs = %{name: "John", phone: "+6281234567890", type: "customer", password: long_password}
      changeset = User.changeset(%User{}, attrs)
      assert "should be at most 128 character(s)" in errors_on(changeset)[:password]
    end

    test "validates Indonesian phone number format" do
      invalid_phones = [
        # Missing +62
        "081234567890",
        # Too short
        "+6281234",
        # Too long
        "+628123456789012345",
        # Wrong country code
        "+1234567890",
        # Contains letters
        "+62abc123456"
      ]

      for phone <- invalid_phones do
        attrs = %{name: "John", phone: phone, type: "customer"}
        changeset = User.changeset(%User{}, attrs)

        assert "must be valid Indonesian phone number (+62xxxxxxxxx)" in errors_on(changeset)[
                 :phone
               ]
      end
    end

    test "validates user type inclusion" do
      attrs = %{name: "John", phone: "+6281234567890", type: "admin"}
      changeset = User.changeset(%User{}, attrs)
      assert "is invalid" in errors_on(changeset)[:type]
    end

    test "validates latitude range" do
      # Invalid latitude
      attrs = %{name: "John", phone: "+6281234567890", type: "driver", latitude: -91}
      changeset = User.changeset(%User{}, attrs)
      assert "must be greater than or equal to -90" in errors_on(changeset)[:latitude]

      attrs = %{name: "John", phone: "+6281234567890", type: "driver", latitude: 91}
      changeset = User.changeset(%User{}, attrs)
      assert "must be less than or equal to 90" in errors_on(changeset)[:latitude]
    end

    test "validates longitude range" do
      # Invalid longitude
      attrs = %{name: "John", phone: "+6281234567890", type: "driver", longitude: -181}
      changeset = User.changeset(%User{}, attrs)
      assert "must be greater than or equal to -180" in errors_on(changeset)[:longitude]

      attrs = %{name: "John", phone: "+6281234567890", type: "driver", longitude: 181}
      changeset = User.changeset(%User{}, attrs)
      assert "must be less than or equal to 180" in errors_on(changeset)[:longitude]
    end

    test "validates rating range" do
      attrs = %{name: "John", phone: "+6281234567890", type: "driver", average_rating: 6}
      changeset = User.changeset(%User{}, attrs)
      assert "must be less than or equal to 5" in errors_on(changeset)[:average_rating]
    end
  end
end
