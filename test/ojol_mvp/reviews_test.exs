defmodule OjolMvp.ReviewsTest do
  use OjolMvp.DataCase

  alias OjolMvp.Reviews

  describe "ratings" do
    alias OjolMvp.Reviews.Rating

    import OjolMvp.ReviewsFixtures

    @invalid_attrs %{comment: nil, rating: nil, reviewer_type: nil}

    test "list_ratings/0 returns all ratings" do
      rating = rating_fixture()
      assert Reviews.list_ratings() == [rating]
    end

    test "get_rating!/1 returns the rating with given id" do
      rating = rating_fixture()
      assert Reviews.get_rating!(rating.id) == rating
    end

    test "create_rating/1 with valid data creates a rating" do
      valid_attrs = %{comment: "some comment", rating: 42, reviewer_type: "some reviewer_type"}

      assert {:ok, %Rating{} = rating} = Reviews.create_rating(valid_attrs)
      assert rating.comment == "some comment"
      assert rating.rating == 42
      assert rating.reviewer_type == "some reviewer_type"
    end

    test "create_rating/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reviews.create_rating(@invalid_attrs)
    end

    test "update_rating/2 with valid data updates the rating" do
      rating = rating_fixture()
      update_attrs = %{comment: "some updated comment", rating: 43, reviewer_type: "some updated reviewer_type"}

      assert {:ok, %Rating{} = rating} = Reviews.update_rating(rating, update_attrs)
      assert rating.comment == "some updated comment"
      assert rating.rating == 43
      assert rating.reviewer_type == "some updated reviewer_type"
    end

    test "update_rating/2 with invalid data returns error changeset" do
      rating = rating_fixture()
      assert {:error, %Ecto.Changeset{}} = Reviews.update_rating(rating, @invalid_attrs)
      assert rating == Reviews.get_rating!(rating.id)
    end

    test "delete_rating/1 deletes the rating" do
      rating = rating_fixture()
      assert {:ok, %Rating{}} = Reviews.delete_rating(rating)
      assert_raise Ecto.NoResultsError, fn -> Reviews.get_rating!(rating.id) end
    end

    test "change_rating/1 returns a rating changeset" do
      rating = rating_fixture()
      assert %Ecto.Changeset{} = Reviews.change_rating(rating)
    end
  end
end
