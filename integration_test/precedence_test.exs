defmodule Ecto.Integration.PrecedenceTest do
  use Ecto.Integration.Case, async: true

  alias Ecto.Integration.Post
  alias Ecto.Integration.TestRepo
  import Ecto.Query

  @posted ~D[2014-01-01]
  @inserted_at ~N[2014-01-01 02:00:00]

  setup do
    TestRepo.insert!(%Post{
      posted: @posted,
      inserted_at: @inserted_at,
      visits: 1,
      counter: 2,
      public: true
    })

    :ok
  end

  test "datetime_add parenthesizes a compound day count" do
    assert [~N[2014-01-04 02:00:00]] =
             TestRepo.all(
               from(p in Post, select: datetime_add(p.inserted_at, p.visits + p.counter, "day"))
             )
  end

  test "datetime_add parenthesizes a compound week count" do
    assert [~N[2014-01-22 02:00:00]] =
             TestRepo.all(
               from(p in Post, select: datetime_add(p.inserted_at, p.visits + p.counter, "week"))
             )
  end

  test "datetime_add parenthesizes a compound millisecond count" do
    TestRepo.delete_all(Post)

    TestRepo.insert!(%Post{
      posted: @posted,
      inserted_at: @inserted_at,
      visits: 500,
      counter: 500
    })

    assert [~N[2014-01-01 02:00:01]] =
             TestRepo.all(
               from(p in Post,
                 select: datetime_add(p.inserted_at, p.visits + p.counter, "millisecond")
               )
             )
  end

  test "date_add parenthesizes a compound day count" do
    assert [~D[2014-01-04]] =
             TestRepo.all(from(p in Post, select: date_add(p.posted, p.visits + p.counter, "day")))
  end

  test "is_nil parenthesizes not" do
    assert [false] = TestRepo.all(from(p in Post, select: is_nil(not p.public)))
  end
end
