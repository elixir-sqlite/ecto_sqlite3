defmodule Ecto.Integration.ValuesTest do
  use Ecto.Integration.Case, async: true

  import Ecto.Query, only: [from: 2, with_cte: 3]

  alias Ecto.Integration.Comment
  alias Ecto.Integration.Post
  alias Ecto.Integration.TestRepo

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
