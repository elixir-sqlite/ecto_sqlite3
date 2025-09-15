defmodule Ecto.Integration.ValuesTest do
  use Ecto.Integration.Case, async: true

  import Ecto.Query, only: [from: 2, with_cte: 3]

  alias Ecto.Integration.Comment
  alias Ecto.Integration.Post
  alias Ecto.Integration.TestRepo

  test "values works with datetime" do
    TestRepo.insert!(%Post{inserted_at: ~N[2000-01-01 00:01:00]})
    TestRepo.insert!(%Post{inserted_at: ~N[2000-01-01 00:02:00]})
    TestRepo.insert!(%Post{inserted_at: ~N[2000-01-01 00:03:00]})

    params = [
      %{id: 1, date: ~N[2000-01-01 00:00:00]},
      %{id: 2, date: ~N[2000-01-01 00:01:00]},
      %{id: 3, date: ~N[2000-01-01 00:02:00]},
      %{id: 4, date: ~N[2000-01-01 00:03:00]}
    ]

    types = %{id: :integer, date: :naive_datetime}

    results =
      from(params in values(params, types),
        left_join: p in Post,
        on: p.inserted_at <= params.date,
        group_by: params.id,
        select: %{id: params.id, count: count(p.id)},
        order_by: count(p.id)
      )
      |> TestRepo.all()

    assert results == [
             %{count: 0, id: 1},
             %{count: 1, id: 2},
             %{count: 2, id: 3},
             %{count: 3, id: 4}
           ]
  end

  test "join to values works" do
    TestRepo.insert!(%Post{id: 1})
    TestRepo.insert!(%Comment{post_id: 1, text: "short"})
    TestRepo.insert!(%Comment{post_id: 1, text: "much longer text"})

    params = [%{id: 1, post_id: 1, n: 0}, %{id: 2, post_id: 1, n: 10}]
    types = %{id: :integer, post_id: :integer, n: :integer}

    results =
      from(p in Post,
        right_join: params in values(params, types),
        on: params.post_id == p.id,
        left_join: c in Comment,
        on: c.post_id == p.id and fragment("LENGTH(?)", c.text) > params.n,
        group_by: params.id,
        select: {params.id, count(c.id)}
      )
      |> TestRepo.all()

    assert [{1, 2}, {2, 1}] = results
  end

  test "values can be used together with CTE" do
    TestRepo.insert!(%Post{id: 1, visits: 42})
    TestRepo.insert!(%Comment{post_id: 1, text: "short"})
    TestRepo.insert!(%Comment{post_id: 1, text: "much longer text"})

    params = [%{id: 1, post_id: 1, n: 0}, %{id: 2, post_id: 1, n: 10}]
    types = %{id: :integer, post_id: :integer, n: :integer}

    cte_query = from(p in Post, select: %{id: p.id, visits: coalesce(p.visits, 0)})

    q = Post |> with_cte("xxx", as: ^cte_query)

    results =
      from(p in q,
        right_join: params in values(params, types),
        on: params.post_id == p.id,
        left_join: c in Comment,
        on: c.post_id == p.id and fragment("LENGTH(?)", c.text) > params.n,
        left_join: cte in "xxx",
        on: cte.id == p.id,
        group_by: params.id,
        select: {params.id, count(c.id), cte.visits}
      )
      |> TestRepo.all()

    assert [{1, 2, 42}, {2, 1, 42}] = results
  end
end
