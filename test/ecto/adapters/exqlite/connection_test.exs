defmodule Ecto.Adapters.Exqlite.ConnectionTest do
  use ExUnit.Case

  alias Ecto.Adapters.Exqlite.Connection
  alias Ecto.Adapters.Exqlite
  # alias Ecto.Migration.Table

  import Ecto.Query
  import Ecto.Migration, only: [table: 1, table: 2, index: 2, index: 3, constraint: 3]
  alias Ecto.Migration.Reference

  defmodule Comment do
    use Ecto.Schema

    schema "comments" do
      field(:content, :string)
    end
  end

  defmodule Post do
    use Ecto.Schema

    schema "posts" do
      field(:title, :string)
      field(:content, :string)
      has_many(:comments, Comment)
    end
  end

  # TODO: Let's rename these or make them more concrete and less terse so that
  #       tests are easier to read and understand what is happening.
  #       @warmwaffles 2021-03-11
  defmodule Schema3 do
    use Ecto.Schema

    schema "schema3" do
      field(:binary, :binary)
    end
  end

  defmodule Schema do
    use Ecto.Schema

    schema "schema" do
      field(:x, :integer)
      field(:y, :integer)
      field(:z, :integer)
      field(:meta, :map)

      has_many(:comments, Ecto.Adapters.Exqlite.ConnectionTest.Schema2,
        references: :x,
        foreign_key: :z
      )

      has_one(:permalink, Ecto.Adapters.Exqlite.ConnectionTest.Schema3,
        references: :y,
        foreign_key: :id
      )
    end
  end

  defmodule Schema2 do
    use Ecto.Schema

    schema "schema2" do
      belongs_to(:post, Ecto.Adapters.Exqlite.ConnectionTest.Schema,
        references: :x,
        foreign_key: :z
      )
    end
  end

  defp plan(query, operation \\ :all) do
    {query, _params} = Ecto.Adapter.Queryable.plan_query(operation, Exqlite, query)
    query
  end

  defp all(query) do
    query
    |> Connection.all()
    |> IO.iodata_to_binary()
  end

  defp update_all(query) do
    query
    |> Connection.update_all()
    |> IO.iodata_to_binary()
  end

  defp delete_all(query) do
    query
    |> Connection.delete_all()
    |> IO.iodata_to_binary()
  end

  defp execute_ddl(query) do
    query
    |> Connection.execute_ddl()
    |> Enum.map(&IO.iodata_to_binary/1)
  end

  defp insert(prefix, table, header, rows, on_conflict, returning, placeholders \\ []) do
    prefix
    |> Connection.insert(table, header, rows, on_conflict, returning, placeholders)
    |> IO.iodata_to_binary()
  end

  defp delete(prefix, table, filter, returning) do
    prefix
    |> Connection.delete(table, filter, returning)
    |> IO.iodata_to_binary()
  end

  test "from" do
    query = Schema |> select([r], r.x) |> plan()
    assert all(query) == ~s{SELECT s0.x FROM schema AS s0}
  end

  test "ignores from with hints" do
    query =
      Schema
      |> from(hints: ["USE INDEX FOO", "USE INDEX BAR"])
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0}
  end

  test "from without schema" do
    query =
      "posts"
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT p0.x FROM posts AS p0}

    query =
      "posts"
      |> select([r], fragment("?", r))
      |> plan()

    assert all(query) == ~s{SELECT p0 FROM posts AS p0}

    query =
      "Posts"
      |> select([:x])
      |> plan()

    assert all(query) == ~s{SELECT P0.x FROM Posts AS P0}

    query =
      "0posts"
      |> select([:x])
      |> plan()

    assert all(query) == ~s{SELECT t0.x FROM 0posts AS t0}

    assert_raise(
      Ecto.QueryError,
      ~r"SQLite3 does not support selecting all fields from posts without a schema",
      fn ->
        from(p in "posts", select: p) |> plan() |> all()
      end
    )
  end

  test "from with subquery" do
    query =
      "posts"
      |> select([r], %{x: r.x, y: r.y})
      |> subquery()
      |> select([r], r.x)
      |> plan()

    assert all(query) == """
           SELECT s0.x \
           FROM (SELECT sp0.x AS x, sp0.y AS y FROM posts AS sp0) AS s0\
           """

    query =
      "posts"
      |> select([r], %{x: r.x, z: r.y})
      |> subquery()
      |> select([r], r)
      |> plan()

    assert all(query) ==
             """
             SELECT s0.x, s0.z \
             FROM (SELECT sp0.x AS x, sp0.y AS z FROM posts AS sp0) AS s0\
             """

    query =
      "posts"
      |> select([r], %{x: r.x, z: r.y})
      |> subquery()
      |> select([r], r)
      |> subquery()
      |> select([r], r)
      |> plan()

    assert all(query) ==
             """
             SELECT s0.x, s0.z \
             FROM (\
             SELECT ss0.x AS x, ss0.z AS z \
             FROM (\
             SELECT ssp0.x AS x, ssp0.y AS z \
             FROM posts AS ssp0\
             ) AS ss0\
             ) AS s0\
             """
  end

  test "common table expression" do
    iteration_query =
      "categories"
      |> join(:inner, [c], t in "tree", on: t.id == c.parent_id)
      |> select([c, t], %{id: c.id, depth: fragment("? + 1", t.depth)})

    cte_query =
      "categories"
      |> where([c], is_nil(c.parent_id))
      |> select([c], %{id: c.id, depth: fragment("1")})
      |> union_all(^iteration_query)

    query =
      Schema
      |> recursive_ctes(true)
      |> with_cte("tree", as: ^cte_query)
      |> join(:inner, [r], t in "tree", on: t.id == r.category_id)
      |> select([r, t], %{x: r.x, category_id: t.id, depth: type(t.depth, :integer)})
      |> plan()

    assert all(query) ==
             """
             WITH RECURSIVE tree AS \
             (SELECT c0.id AS id, 1 AS depth FROM categories AS c0 WHERE (c0.parent_id IS NULL) \
             UNION ALL \
             SELECT c0.id, t1.depth + 1 FROM categories AS c0 \
             INNER JOIN tree AS t1 ON t1.id = c0.parent_id) \
             SELECT s0.x, t1.id, CAST(t1.depth AS INTEGER) \
             FROM schema AS s0 \
             INNER JOIN tree AS t1 ON t1.id = s0.category_id\
             """
  end

  test "reference common table in union" do
    comments_scope_query =
      "comments"
      |> where([c], is_nil(c.deleted_at))
      |> select([c], %{entity_id: c.entity_id, text: c.text})

    posts_query =
      "posts"
      |> join(:inner, [p], c in "comments_scope", on: c.entity_id == p.guid)
      |> select([p, c], [p.title, c.text])

    videos_query =
      "videos"
      |> join(:inner, [v], c in "comments_scope", on: c.entity_id == v.guid)
      |> select([v, c], [v.title, c.text])

    query =
      posts_query
      |> union_all(^videos_query)
      |> with_cte("comments_scope", as: ^comments_scope_query)
      |> plan()

    assert all(query) ==
             """
             WITH comments_scope AS (\
             SELECT c0.entity_id AS entity_id, c0.text AS text \
             FROM comments AS c0 WHERE (c0.deleted_at IS NULL)) \
             SELECT p0.title, c1.text \
             FROM posts AS p0 \
             INNER JOIN comments_scope AS c1 ON c1.entity_id = p0.guid \
             UNION ALL \
             SELECT v0.title, c1.text \
             FROM videos AS v0 \
             INNER JOIN comments_scope AS c1 ON c1.entity_id = v0.guid\
             """
  end

  @raw_sql_cte """
  SELECT * FROM categories WHERE c.parent_id IS NULL \
  UNION ALL \
  SELECT * FROM categories AS c, category_tree AS ct WHERE ct.id = c.parent_id\
  """

  test "fragment common table expression" do
    query =
      Schema
      |> recursive_ctes(true)
      |> with_cte("tree", as: fragment(@raw_sql_cte))
      |> join(:inner, [p], c in "tree", on: c.id == p.category_id)
      |> select([r], r.x)
      |> plan()

    assert all(query) ==
             """
             WITH RECURSIVE tree AS (#{@raw_sql_cte}) \
             SELECT s0.x \
             FROM schema AS s0 \
             INNER JOIN tree AS t1 ON t1.id = s0.category_id\
             """
  end

  test "common table expression update_all" do
    cte_query =
      from(
        x in Schema,
        order_by: [asc: :id],
        limit: 10,
        select: %{id: x.id}
      )

    query =
      Schema
      |> with_cte("target_rows", as: ^cte_query)
      |> join(:inner, [row], target in "target_rows", on: target.id == row.id)
      |> update(set: [x: 123])
      |> plan(:update_all)

    assert update_all(query) ==
             """
             WITH target_rows AS \
             (SELECT s0.id AS id FROM schema AS s0 ORDER BY s0.id LIMIT 10) \
             UPDATE schema AS s0 \
             SET x = 123 \
             FROM target_rows AS t1 \
             WHERE (t1.id = s0.id)\
             """
  end

  test "common table expression delete_all" do
    cte_query = from(x in Schema, order_by: [asc: :id], limit: 10, select: %{id: x.id})

    query =
      Schema
      |> with_cte("target_rows", as: ^cte_query)
      |> plan(:delete_all)

    # TODO: This is valid in sqlite
    # https://sqlite.org/lang_delete.html
    assert delete_all(query) ==
             """
             WITH target_rows AS \
             (SELECT s0.id AS id FROM schema AS s0 ORDER BY s0.id LIMIT 10) \
             DELETE \
             FROM schema AS s0\
             """
  end

  test "select" do
    query =
      Schema
      |> select([r], {r.x, r.y})
      |> plan()

    assert all(query) == ~s{SELECT s0.x, s0.y FROM schema AS s0}

    query =
      Schema
      |> select([r], [r.x, r.y])
      |> plan()

    assert all(query) == ~s{SELECT s0.x, s0.y FROM schema AS s0}

    query =
      Schema
      |> select([r], struct(r, [:x, :y]))
      |> plan()

    assert all(query) == ~s{SELECT s0.x, s0.y FROM schema AS s0}
  end

  test "aggregates" do
    query =
      Schema
      |> select(count())
      |> plan()

    assert all(query) == ~s{SELECT count(*) FROM schema AS s0}
  end

  test "aggregate filters" do
    query = Schema |> select([r], count(r.x) |> filter(r.x > 10)) |> plan()
    assert all(query) == ~s{SELECT count(s0.x) FILTER (WHERE s0.x > 10) FROM schema AS s0}

    query = Schema |> select([r], count(r.x) |> filter(r.x > 10 and r.x < 50)) |> plan()
    assert all(query) == ~s{SELECT count(s0.x) FILTER (WHERE (s0.x > 10) AND (s0.x < 50)) FROM schema AS s0}

    query = Schema |> select([r], count() |> filter(r.x > 10)) |> plan()
    assert all(query) == ~s{SELECT count(*) FILTER (WHERE s0.x > 10) FROM schema AS s0}
  end

  test "distinct" do
    query =
      Schema
      |> distinct([r], true)
      |> select([r], {r.x, r.y})
      |> plan()

    assert all(query) == ~s{SELECT DISTINCT s0.x, s0.y FROM schema AS s0}

    query =
      Schema
      |> distinct([r], false)
      |> select([r], {r.x, r.y})
      |> plan()

    assert all(query) == ~s{SELECT s0.x, s0.y FROM schema AS s0}

    query =
      Schema
      |> distinct(true)
      |> select([r], {r.x, r.y})
      |> plan()

    assert all(query) == ~s{SELECT DISTINCT s0.x, s0.y FROM schema AS s0}

    query =
      Schema
      |> distinct(false)
      |> select([r], {r.x, r.y})
      |> plan()

    assert all(query) == ~s{SELECT s0.x, s0.y FROM schema AS s0}

    assert_raise(
      Ecto.QueryError,
      ~r"DISTINCT with multiple columns is not supported by SQLite3",
      fn ->
        Schema
        |> distinct([r], [r.x, r.y])
        |> select([r], {r.x, r.y})
        |> plan()
        |> all()
      end
    )
  end

  test "coalesce" do
    query =
      Schema
      |> select([s], coalesce(s.x, 5))
      |> plan()

    assert all(query) == ~s{SELECT coalesce(s0.x, 5) FROM schema AS s0}
  end

  test "where" do
    query =
      Schema
      |> where([r], r.x == 42)
      |> where([r], r.y != 43)
      |> select([r], r.x)
      |> plan()

    assert all(query) ==
             ~s{SELECT s0.x FROM schema AS s0 WHERE (s0.x = 42) AND (s0.y != 43)}

    query =
      Schema
      |> where([r], {r.x, r.y} > {1, 2})
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0 WHERE ((s0.x,s0.y) > (1,2))}
  end

  test "or_where" do
    query =
      Schema
      |> or_where([r], r.x == 42)
      |> or_where([r], r.y != 43)
      |> select([r], r.x)
      |> plan()

    assert all(query) ==
             ~s{SELECT s0.x FROM schema AS s0 WHERE (s0.x = 42) OR (s0.y != 43)}

    query =
      Schema
      |> or_where([r], r.x == 42)
      |> or_where([r], r.y != 43)
      |> where([r], r.z == 44)
      |> select([r], r.x)
      |> plan()

    assert all(query) ==
             ~s{SELECT s0.x FROM schema AS s0 WHERE ((s0.x = 42) OR (s0.y != 43)) AND (s0.z = 44)}
  end

  test "order by" do
    query =
      Schema
      |> order_by([r], r.x)
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0 ORDER BY s0.x}

    query =
      Schema
      |> order_by([r], [r.x, r.y])
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0 ORDER BY s0.x, s0.y}

    query =
      Schema
      |> order_by([r], asc: r.x, desc: r.y)
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0 ORDER BY s0.x, s0.y DESC}

    query =
      Schema
      |> order_by([r], [])
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0}

    for dir <- [:asc_nulls_first, :asc_nulls_last, :desc_nulls_first, :desc_nulls_last] do
      assert_raise(
        Ecto.QueryError,
        ~r"#{dir} is not supported in ORDER BY in SQLite3",
        fn ->
          Schema
          |> order_by([r], [{^dir, r.x}])
          |> select([r], r.x)
          |> plan()
          |> all()
        end
      )
    end
  end

  test "union and union all" do
    base_query =
      Schema
      |> select([r], r.x)
      |> order_by(fragment("rand"))
      |> offset(10)
      |> limit(5)

    union_query1 =
      Schema
      |> select([r], r.y)
      |> order_by([r], r.y)
      |> offset(20)
      |> limit(40)

    union_query2 =
      Schema
      |> select([r], r.z)
      |> order_by([r], r.z)
      |> offset(30)
      |> limit(60)

    query =
      base_query
      |> union(^union_query1)
      |> union(^union_query2)
      |> plan()

    assert all(query) ==
             """
             SELECT s0.x FROM schema AS s0 \
             UNION SELECT s0.y FROM schema AS s0 ORDER BY s0.y LIMIT 40 OFFSET 20 \
             UNION SELECT s0.z FROM schema AS s0 ORDER BY s0.z LIMIT 60 OFFSET 30 \
             ORDER BY rand LIMIT 5 OFFSET 10\
             """

    query =
      base_query
      |> union_all(^union_query1)
      |> union_all(^union_query2)
      |> plan()

    assert all(query) ==
             """
             SELECT s0.x FROM schema AS s0 \
             UNION ALL SELECT s0.y FROM schema AS s0 ORDER BY s0.y LIMIT 40 OFFSET 20 \
             UNION ALL SELECT s0.z FROM schema AS s0 ORDER BY s0.z LIMIT 60 OFFSET 30 \
             ORDER BY rand LIMIT 5 OFFSET 10\
             """
  end

  test "except and except all" do
    base_query =
      Schema
      |> select([r], r.x)
      |> order_by(fragment("rand"))
      |> offset(10)
      |> limit(5)

    except_query1 =
      Schema
      |> select([r], r.y)
      |> order_by([r], r.y)
      |> offset(20)
      |> limit(40)

    except_query2 =
      Schema
      |> select([r], r.z)
      |> order_by([r], r.z)
      |> offset(30)
      |> limit(60)

    query =
      base_query
      |> except(^except_query1)
      |> except(^except_query2)
      |> plan()

    assert all(query) ==
             """
             SELECT s0.x FROM schema AS s0 \
             EXCEPT SELECT s0.y FROM schema AS s0 ORDER BY s0.y LIMIT 40 OFFSET 20 \
             EXCEPT SELECT s0.z FROM schema AS s0 ORDER BY s0.z LIMIT 60 OFFSET 30 \
             ORDER BY rand LIMIT 5 OFFSET 10\
             """

    assert_raise(
      Ecto.QueryError,
      fn ->
        base_query
        |> except_all(^except_query1)
        |> except_all(^except_query2)
        |> plan()
        |> all()
      end
    )
  end

  test "intersect and intersect all" do
    base_query =
      Schema
      |> select([r], r.x)
      |> order_by(fragment("rand"))
      |> offset(10)
      |> limit(5)

    intersect_query1 =
      Schema
      |> select([r], r.y)
      |> order_by([r], r.y)
      |> offset(20)
      |> limit(40)

    intersect_query2 =
      Schema
      |> select([r], r.z)
      |> order_by([r], r.z)
      |> offset(30)
      |> limit(60)

    query =
      base_query
      |> intersect(^intersect_query1)
      |> intersect(^intersect_query2)
      |> plan()

    assert all(query) ==
             """
             SELECT s0.x FROM schema AS s0 \
             INTERSECT SELECT s0.y FROM schema AS s0 ORDER BY s0.y LIMIT 40 OFFSET 20 \
             INTERSECT SELECT s0.z FROM schema AS s0 ORDER BY s0.z LIMIT 60 OFFSET 30 \
             ORDER BY rand LIMIT 5 OFFSET 10\
             """

    assert_raise(
      Ecto.QueryError,
      fn ->
        base_query
        |> intersect_all(^intersect_query1)
        |> intersect_all(^intersect_query2)
        |> plan()
        |> all()
      end
    )
  end

  test "limit and offset" do
    query =
      Schema
      |> limit([r], 3)
      |> select([], true)
      |> plan()

    assert all(query) == ~s{SELECT 1 FROM schema AS s0 LIMIT 3}

    query =
      Schema
      |> offset([r], 5)
      |> select([], true)
      |> plan()

    assert all(query) == ~s{SELECT 1 FROM schema AS s0 OFFSET 5}

    query =
      Schema
      |> offset([r], 5)
      |> limit([r], 3)
      |> select([], true)
      |> plan()

    assert all(query) == ~s{SELECT 1 FROM schema AS s0 LIMIT 3 OFFSET 5}
  end

  test "lock" do
    assert_raise(
      ArgumentError,
      "locks are not supported by SQLite3",
      fn ->
        Schema
        |> lock("LOCK IN SHARE MODE")
        |> select([], true)
        |> plan()
        |> all()
      end
    )

    assert_raise(
      ArgumentError,
      "locks are not supported by SQLite3",
      fn ->
        Schema
        |> lock([p], fragment("UPDATE on ?", p))
        |> select([], true)
        |> plan()
        |> all()
      end
    )
  end

  test "string escape" do
    query =
      "schema"
      |> where(foo: "'\\  ")
      |> select([], true)
      |> plan()

    assert all(query) == ~s{SELECT 1 FROM schema AS s0 WHERE (s0.foo = '''\\\\  ')}

    query =
      "schema"
      |> where(foo: "'")
      |> select([], true)
      |> plan()

    assert all(query) == ~s{SELECT 1 FROM schema AS s0 WHERE (s0.foo = '''')}
  end

  test "binary ops" do
    query =
      Schema
      |> select([r], r.x == 2)
      |> plan()

    assert all(query) == ~s{SELECT s0.x = 2 FROM schema AS s0}

    query =
      Schema
      |> select([r], r.x != 2)
      |> plan()

    assert all(query) == ~s{SELECT s0.x != 2 FROM schema AS s0}

    query =
      Schema
      |> select([r], r.x <= 2)
      |> plan()

    assert all(query) == ~s{SELECT s0.x <= 2 FROM schema AS s0}

    query =
      Schema
      |> select([r], r.x >= 2)
      |> plan()

    assert all(query) == ~s{SELECT s0.x >= 2 FROM schema AS s0}

    query =
      Schema
      |> select([r], r.x < 2)
      |> plan()

    assert all(query) == ~s{SELECT s0.x < 2 FROM schema AS s0}

    query =
      Schema
      |> select([r], r.x > 2)
      |> plan()

    assert all(query) == ~s{SELECT s0.x > 2 FROM schema AS s0}

    query =
      Schema
      |> select([r], r.x + 2)
      |> plan()

    assert all(query) == ~s{SELECT s0.x + 2 FROM schema AS s0}
  end

  test "is_nil" do
    query =
      Schema
      |> select([r], is_nil(r.x))
      |> plan()

    assert all(query) == ~s{SELECT s0.x IS NULL FROM schema AS s0}

    query =
      Schema
      |> select([r], not is_nil(r.x))
      |> plan()

    assert all(query) == ~s{SELECT NOT (s0.x IS NULL) FROM schema AS s0}

    query =
      "schema"
      |> select([r], r.x == is_nil(r.y))
      |> plan()

    assert all(query) == ~s{SELECT s0.x = (s0.y IS NULL) FROM schema AS s0}
  end

  test "order_by and types" do
    query =
      "schema3"
      |> order_by([e], type(fragment("?", e.binary), ^:decimal))
      |> select(true)
      |> plan()

    assert all(query) == "SELECT 1 FROM schema3 AS s0 ORDER BY (s0.binary + 0)"
  end

  test "fragments" do
    query =
      Schema
      |> select([r], fragment("now"))
      |> plan()

    assert all(query) == ~s{SELECT now FROM schema AS s0}

    query =
      Schema
      |> select([r], fragment("fun(?)", r))
      |> plan()

    assert all(query) == ~s{SELECT fun(s0) FROM schema AS s0}

    query =
      Schema
      |> select([r], fragment("lcase(?)", r.x))
      |> plan()

    assert all(query) == ~s{SELECT lcase(s0.x) FROM schema AS s0}

    query =
      Schema
      |> select([r], r.x)
      |> where([], fragment(~s|? = "query\\?"|, ^10))
      |> plan()

    assert all(query) == ~s|SELECT s0.x FROM schema AS s0 WHERE (? = "query?")|

    value = 13

    query =
      Schema
      |> select([r], fragment("lcase(?, ?)", r.x, ^value))
      |> plan()

    assert all(query) == ~s{SELECT lcase(s0.x, ?) FROM schema AS s0}

    assert_raise(
      Ecto.QueryError,
      fn ->
        Schema
        |> select([], fragment(title: 2))
        |> plan()
        |> all()
      end
    )
  end

  test "literals" do
    query =
      "schema"
      |> where(foo: true)
      |> select([], true)
      |> plan()

    assert all(query) == ~s{SELECT 1 FROM schema AS s0 WHERE (s0.foo = 1)}

    query =
      "schema"
      |> where(foo: false)
      |> select([], true)
      |> plan()

    assert all(query) == ~s{SELECT 1 FROM schema AS s0 WHERE (s0.foo = 0)}

    query =
      "schema"
      |> where(foo: "abc")
      |> select([], true)
      |> plan()

    assert all(query) == ~s{SELECT 1 FROM schema AS s0 WHERE (s0.foo = 'abc')}

    query =
      "schema"
      |> where(foo: 123)
      |> select([], true)
      |> plan()

    assert all(query) == ~s{SELECT 1 FROM schema AS s0 WHERE (s0.foo = 123)}

    query =
      "schema"
      |> where(foo: 123.0)
      |> select([], true)
      |> plan()

    assert all(query) == ~s{SELECT 1 FROM schema AS s0 WHERE (s0.foo = (0 + 123.0))}
  end

  # TODO: We need to determine what format to store the UUID. Is it Text or binary 16?
  #       Are we going for readability or for compactness?
  test "tagged type" do
    query =
      Schema
      |> select([], type(^"601d74e4-a8d3-4b6e-8365-eddb4c893327", Ecto.UUID))
      |> plan()

    assert all(query) == ~s{SELECT CAST(? AS TEXT) FROM schema AS s0}
  end

  test "string type" do
    query =
      Schema
      |> select([], type(^"test", :string))
      |> plan()

    assert all(query) == ~s{SELECT CAST(? AS TEXT) FROM schema AS s0}
  end

  test "json_extract_path" do
    query = Schema |> select([s], json_extract_path(s.meta, [0, 1])) |> plan()
    assert all(query) == ~s{SELECT json_extract(s0.meta, '$[0][1]') FROM schema AS s0}

    query = Schema |> select([s], json_extract_path(s.meta, ["a", "b"])) |> plan()
    assert all(query) == ~s{SELECT json_extract(s0.meta, '$.a.b') FROM schema AS s0}

    query = Schema |> select([s], json_extract_path(s.meta, ["'a"])) |> plan()
    assert all(query) == ~s{SELECT json_extract(s0.meta, '$.''a') FROM schema AS s0}

    query = Schema |> select([s], json_extract_path(s.meta, ["\"a"])) |> plan()
    assert all(query) == ~s{SELECT json_extract(s0.meta, '$.\\"a') FROM schema AS s0}

    query = Schema |> select([s], s.meta["author"]["name"]) |> plan()
    assert all(query) == ~s{SELECT json_extract(s0.meta, '$.author.name') FROM schema AS s0}
  end

  test "nested expressions" do
    z = 123

    query =
      (r in Schema)
      |> from([])
      |> select([r], (r.x > 0 and r.y > ^(-z)) or true)
      |> plan()

    assert all(query) == ~s{SELECT ((s0.x > 0) AND (s0.y > ?)) OR 1 FROM schema AS s0}
  end

  test "in expression" do
    query =
      Schema
      |> select([e], 1 in [1, e.x, 3])
      |> plan()

    assert all(query) == ~s{SELECT 1 IN (1,s0.x,3) FROM schema AS s0}

    query =
      Schema
      |> select([e], 1 in ^[])
      |> plan()

    assert all(query) == ~s{SELECT 0 FROM schema AS s0}

    query =
      Schema
      |> select([e], 1 in ^[1, 2, 3])
      |> plan()

    assert all(query) == ~s{SELECT 1 IN (?,?,?) FROM schema AS s0}

    query =
      Schema
      |> select([e], 1 in [1, ^2, 3])
      |> plan()

    assert all(query) == ~s{SELECT 1 IN (1,?,3) FROM schema AS s0}

    query =
      Schema
      |> select([e], e.x == ^0 or e.x in ^[1, 2, 3] or e.x == ^4)
      |> plan()

    assert all(query) ==
             ~s{SELECT ((s0.x = ?) OR s0.x IN (?,?,?)) OR (s0.x = ?) FROM schema AS s0}

    query =
      Schema
      |> select([e], e in [1, 2, 3])
      |> plan()

    assert all(query) == "SELECT s0 IN (SELECT value FROM JSON_EACH('[1,2,3]')) FROM schema AS s0"
  end

  test "in subquery" do
    posts =
      "posts"
      |> where(title: ^"hello")
      |> select([p], p.id)
      |> subquery()

    query =
      "comments"
      |> where([c], c.post_id in subquery(posts))
      |> select([c], c.x)
      |> plan()

    assert all(query) ==
             """
             SELECT c0.x FROM comments AS c0 \
             WHERE (c0.post_id IN (SELECT sp0.id FROM posts AS sp0 WHERE (sp0.title = ?)))\
             """

    posts =
      "posts"
      |> where(title: parent_as(:comment).subtitle)
      |> select([p], p.id)
      |> subquery()

    query =
      "comments"
      |> from(as: :comment)
      |> where([c], c.post_id in subquery(posts))
      |> select([c], c.x)
      |> plan()

    assert all(query) ==
             """
             SELECT c0.x FROM comments AS c0 \
             WHERE (c0.post_id IN (SELECT sp0.id FROM posts AS sp0 WHERE (sp0.title = c0.subtitle)))\
             """
  end

  test "having" do
    query =
      Schema
      |> having([p], p.x == p.x)
      |> select([p], p.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0 HAVING (s0.x = s0.x)}

    query =
      Schema
      |> having([p], p.x == p.x)
      |> having([p], p.y == p.y)
      |> select([p], [p.y, p.x])
      |> plan()

    assert all(query) ==
             """
             SELECT s0.y, s0.x \
             FROM schema AS s0 \
             HAVING (s0.x = s0.x) \
             AND (s0.y = s0.y)\
             """
  end

  test "or_having" do
    query =
      Schema
      |> or_having([p], p.x == p.x)
      |> select([p], p.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0 HAVING (s0.x = s0.x)}

    query =
      Schema
      |> or_having([p], p.x == p.x)
      |> or_having([p], p.y == p.y)
      |> select([p], [p.y, p.x])
      |> plan()

    assert all(query) ==
             """
             SELECT s0.y, s0.x \
             FROM schema AS s0 \
             HAVING (s0.x = s0.x) \
             OR (s0.y = s0.y)\
             """
  end

  test "group by" do
    query =
      Schema
      |> group_by([r], r.x)
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0 GROUP BY s0.x}

    query =
      Schema
      |> group_by([r], 2)
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0 GROUP BY 2}

    query =
      Schema
      |> group_by([r], [r.x, r.y])
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0 GROUP BY s0.x, s0.y}

    query =
      Schema
      |> group_by([r], [])
      |> select([r], r.x)
      |> plan()

    assert all(query) == ~s{SELECT s0.x FROM schema AS s0}
  end

  test "interpolated values" do
    cte1 =
      "schema1"
      |> select([m], %{id: m.id, smth: ^true})
      |> where([], fragment("?", ^1))

    union =
      "schema1"
      |> select([m], {m.id, ^true})
      |> where([], fragment("?", ^5))

    union_all =
      "schema2"
      |> select([m], {m.id, ^false})
      |> where([], fragment("?", ^6))

    query =
      Schema
      |> with_cte("cte1", as: ^cte1)
      |> with_cte("cte2", as: fragment("SELECT * FROM schema WHERE ?", ^2))
      |> select([m], {m.id, ^0})
      |> join(:inner, [], Schema2, on: fragment("?", ^true))
      |> join(:inner, [], Schema2, on: fragment("?", ^false))
      |> where([], fragment("?", ^true))
      |> where([], fragment("?", ^false))
      |> having([], fragment("?", ^true))
      |> having([], fragment("?", ^false))
      |> group_by([], fragment("?", ^3))
      |> group_by([], fragment("?", ^4))
      |> union(^union)
      |> union_all(^union_all)
      |> order_by([], fragment("?", ^7))
      |> limit([], ^8)
      |> offset([], ^9)
      |> plan()

    assert all(query) ==
             """
             WITH cte1 AS (SELECT s0.id AS id, ? AS smth FROM schema1 AS s0 WHERE (?)), \
             cte2 AS (SELECT * FROM schema WHERE ?) \
             SELECT s0.id, ? FROM schema AS s0 INNER JOIN schema2 AS s1 ON ? \
             INNER JOIN schema2 AS s2 ON ? WHERE (?) AND (?) \
             GROUP BY ?, ? HAVING (?) AND (?) \
             UNION SELECT s0.id, ? FROM schema1 AS s0 WHERE (?) \
             UNION ALL SELECT s0.id, ? FROM schema2 AS s0 WHERE (?) \
             ORDER BY ? LIMIT ? OFFSET ?\
             """
  end

  test "fragments allow ? to be escaped with backslash" do
    query =
      (e in "schema")
      |> from(
        where: fragment(~s|? = "query\\?"|, e.start_time),
        select: true
      )
      |> plan()

    result = ~s|SELECT 1 FROM schema AS s0 WHERE (s0.start_time = "query?")|

    assert all(query) == result
  end

  ##
  ## *_all
  ##

  test "update all" do
    query =
      (m in Schema)
      |> from(update: [set: [x: 0]])
      |> plan(:update_all)

    assert update_all(query) == ~s{UPDATE schema AS s0 SET x = 0}

    query =
      (m in Schema)
      |> from(update: [set: [x: 0], inc: [y: 1, z: -3]])
      |> plan(:update_all)

    # TODO: should probably be "y = s0.y + 1"
    # table-name.column-name is not allowed on the left hand side of SET
    # but is allowed on right hand side, and we should err towards being more explicit
    assert update_all(query) ==
             """
             UPDATE schema AS s0 \
             SET \
             x = 0, \
             y = y + 1, \
             z = z + -3\
             """

    query =
      (e in Schema)
      |> from(where: e.x == 123, update: [set: [x: 0]])
      |> plan(:update_all)

    assert update_all(query) ==
             """
             UPDATE schema AS s0 \
             SET x = 0 \
             WHERE (s0.x = 123)\
             """

    query =
      (m in Schema)
      |> from(update: [set: [x: ^0]])
      |> plan(:update_all)

    assert update_all(query) == ~s|UPDATE schema AS s0 SET x = ?|

    query =
      Schema
      |> join(:inner, [p], q in Schema2, on: p.x == q.z)
      |> update([_], set: [x: 0])
      |> plan(:update_all)

    assert update_all(query) ==
             """
             UPDATE schema AS s0 \
             SET \
             x = 0 \
             FROM schema2 AS s1 \
             WHERE (s0.x = s1.z)\
             """

    query =
      (e in Schema)
      |> from(
        where: e.x == 123,
        update: [set: [x: 0]],
        join: q in Schema2,
        on: e.x == q.z
      )
      |> plan(:update_all)

    assert update_all(query) ==
             """
             UPDATE schema AS s0 \
             SET x = 0 \
             FROM schema2 AS s1 \
             WHERE (s0.x = s1.z) \
             AND (s0.x = 123)\
             """

    query = from(
      p in Post,
      where: p.title == ^"foo",
      select: p.content,
      update: [set: [title: "bar"]]
    ) |> plan(:update_all)
    assert update_all(query) ==
             """
             UPDATE posts AS p0 \
             SET title = 'bar' \
             WHERE (p0.title = ?) \
             RETURNING p0.content\
             """
  end

  test "update all with prefix" do
    query =
      (m in Schema)
      |> from(update: [set: [x: 0]])
      |> Map.put(:prefix, "prefix")
      |> plan(:update_all)

    assert update_all(query) == ~s{UPDATE prefix.schema AS s0 SET x = 0}

    query =
      (m in Schema)
      |> from(prefix: "first", update: [set: [x: 0]])
      |> Map.put(:prefix, "prefix")
      |> plan(:update_all)

    assert update_all(query) == ~s{UPDATE first.schema AS s0 SET x = 0}
  end

  test "update all with returning" do
    query =
      from(p in Post, update: [set: [title: "foo"]])
      |> select([p], p)
      |> plan(:update_all)
    assert update_all(query) ==
             """
             UPDATE posts AS p0 \
             SET title = 'foo' \
             RETURNING p0.id, p0.title, p0.content\
             """

    query =
      from(m in Schema, update: [set: [x: ^1]])
      |> where([m], m.x == ^2)
      |> select([m], m.x == ^3)
      |> plan(:update_all)
    assert update_all(query) ==
             """
             UPDATE schema AS s0 \
             SET x = ? \
             WHERE (s0.x = ?) \
             RETURNING s0.x = ?\
             """
  end

  test "delete all" do
    query =
      Schema
      |> Ecto.Queryable.to_query()
      |> plan()

    assert delete_all(query) == ~s{DELETE FROM schema AS s0}

    query =
      (e in Schema)
      |> from(where: e.x == 123)
      |> plan()

    assert delete_all(query) == ~s{DELETE FROM schema AS s0 WHERE (s0.x = 123)}

    query =
      (e in Schema)
      |> from(where: e.x == 123, select: e.x)
      |> plan()
    assert delete_all(query) ==
            """
            DELETE FROM schema AS s0 \
            WHERE (s0.x = 123) RETURNING s0.x\
            """
  end

  test "delete all with returning" do
    query = Post |> Ecto.Queryable.to_query |> select([m], m) |> plan()
    assert delete_all(query) ==
           """
           DELETE FROM posts AS p0 \
           RETURNING p0.id, p0.title, p0.content\
           """
  end

  test "delete all with prefix" do
    query =
      Schema
      |> Ecto.Queryable.to_query()
      |> Map.put(:prefix, "prefix")
      |> plan()

    assert delete_all(query) == ~s{DELETE FROM prefix.schema AS s0}

    query =
      Schema
      |> from(prefix: "first")
      |> Map.put(:prefix, "prefix")
      |> plan()

    assert delete_all(query) == ~s{DELETE FROM first.schema AS s0}
  end

  ##
  ## Partitions and windows
  ##

  describe "windows" do
    test "one window" do
      query =
        Schema
        |> select([r], r.x)
        |> windows([r], w: [partition_by: r.x])
        |> plan()

      assert all(query) ==
               """
               SELECT s0.x \
               FROM schema AS s0 WINDOW w AS (PARTITION BY s0.x)\
               """
    end

    test "two windows" do
      query =
        Schema
        |> select([r], r.x)
        |> windows([r], w1: [partition_by: r.x], w2: [partition_by: r.y])
        |> plan()

      assert all(query) ==
               """
               SELECT s0.x \
               FROM schema AS s0 WINDOW w1 AS (PARTITION BY s0.x), \
               w2 AS (PARTITION BY s0.y)\
               """
    end

    test "count over window" do
      query =
        Schema
        |> windows([r], w: [partition_by: r.x])
        |> select([r], count(r.x) |> over(:w))
        |> plan()

      assert all(query) ==
               """
               SELECT count(s0.x) OVER w \
               FROM schema AS s0 WINDOW w AS (PARTITION BY s0.x)\
               """
    end

    test "count over all" do
      query =
        Schema
        |> select([r], count(r.x) |> over)
        |> plan()

      assert all(query) == ~s{SELECT count(s0.x) OVER () FROM schema AS s0}
    end

    test "row_number over all" do
      query =
        Schema
        |> select(row_number |> over)
        |> plan()

      assert all(query) == ~s{SELECT row_number() OVER () FROM schema AS s0}
    end

    test "nth_value over all" do
      query =
        Schema
        |> select([r], nth_value(r.x, 42) |> over)
        |> plan()

      assert all(query) ==
               """
               SELECT nth_value(s0.x, 42) OVER () \
               FROM schema AS s0\
               """
    end

    test "lag/2 over all" do
      query =
        Schema
        |> select([r], lag(r.x, 42) |> over)
        |> plan()

      assert all(query) == ~s{SELECT lag(s0.x, 42) OVER () FROM schema AS s0}
    end

    test "custom aggregation over all" do
      query =
        Schema
        |> select([r], fragment("custom_function(?)", r.x) |> over)
        |> plan()

      assert all(query) ==
               """
               SELECT custom_function(s0.x) OVER () \
               FROM schema AS s0\
               """
    end

    test "partition by and order by on window" do
      query =
        Schema
        |> windows([r], w: [partition_by: [r.x, r.z], order_by: r.x])
        |> select([r], r.x)
        |> plan()

      assert all(query) ==
               """
               SELECT s0.x \
               FROM schema AS s0 WINDOW w AS (PARTITION BY s0.x, s0.z ORDER BY s0.x)\
               """
    end

    test "partition by and order by on over" do
      query =
        Schema
        |> select([r], count(r.x) |> over(partition_by: [r.x, r.z], order_by: r.x))
        |> plan()

      assert all(query) ==
               """
               SELECT count(s0.x) OVER (PARTITION BY s0.x, s0.z ORDER BY s0.x) \
               FROM schema AS s0\
               """
    end

    test "frame clause" do
      query =
        Schema
        |> select(
          [r],
          count(r.x)
          |> over(
            partition_by: [r.x, r.z],
            order_by: r.x,
            frame: fragment("ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING")
          )
        )
        |> plan()

      assert all(query) ==
               """
               SELECT count(s0.x) OVER (\
               PARTITION BY s0.x, \
               s0.z \
               ORDER BY s0.x \
               ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING\
               ) \
               FROM schema AS s0\
               """
    end
  end

  ##
  ## Joins
  ##

  test "join" do
    query =
      Schema
      |> join(:inner, [p], q in Schema2, on: p.x == q.z)
      |> select([], true)
      |> plan()

    assert all(query) ==
             """
             SELECT 1 \
             FROM schema AS s0 \
             INNER JOIN schema2 AS s1 ON s0.x = s1.z\
             """

    query =
      Schema
      |> join(:inner, [p], q in Schema2, on: p.x == q.z)
      |> join(:inner, [], Schema, on: true)
      |> select([], true)
      |> plan()

    assert all(query) ==
             """
             SELECT 1 FROM schema AS s0 INNER JOIN schema2 AS s1 ON s0.x = s1.z \
             INNER JOIN schema AS s2 ON 1\
             """
  end

  test "join ignores hints" do
    query =
      Schema
      |> join(:inner, [p], q in Schema2, hints: ["USE INDEX FOO", "USE INDEX BAR"])
      |> select([], true)
      |> plan()

    assert all(query) ==
             """
             SELECT 1 \
             FROM schema AS s0 \
             INNER JOIN schema2 AS s1 ON 1\
             """
  end

  test "join with nothing bound" do
    query =
      Schema
      |> join(:inner, [], q in Schema2, on: q.z == q.z)
      |> select([], true)
      |> plan()

    assert all(query) ==
             """
             SELECT 1 \
             FROM schema AS s0 \
             INNER JOIN schema2 AS s1 ON s1.z = s1.z\
             """
  end

  test "join without schema" do
    query =
      "posts"
      |> join(:inner, [p], q in "comments", on: p.x == q.z)
      |> select([], true)
      |> plan()

    assert all(query) ==
             """
             SELECT 1 \
             FROM posts AS p0 \
             INNER JOIN comments AS c1 ON p0.x = c1.z\
             """
  end

  test "join with subquery" do
    posts =
      "posts"
      |> where(title: ^"hello")
      |> select([r], %{x: r.x, y: r.y})
      |> subquery()

    query =
      "comments"
      |> join(:inner, [c], p in subquery(posts), on: true)
      |> select([_, p], p.x)
      |> plan()

    assert all(query) ==
             """
             SELECT s1.x FROM comments AS c0 \
             INNER JOIN (\
             SELECT sp0.x AS x, sp0.y AS y \
             FROM posts AS sp0 \
             WHERE (sp0.title = ?)\
             ) AS s1 ON 1\
             """

    posts =
      "posts"
      |> where(title: ^"hello")
      |> select([r], %{x: r.x, z: r.y})
      |> subquery()

    query =
      "comments"
      |> join(:inner, [c], p in subquery(posts), on: true)
      |> select([_, p], p)
      |> plan()

    assert all(query) ==
             """
             SELECT s1.x, s1.z FROM comments AS c0 \
             INNER JOIN (\
             SELECT sp0.x AS x, sp0.y AS z \
             FROM posts AS sp0 \
             WHERE (sp0.title = ?)\
             ) AS s1 ON 1\
             """

    posts =
      "posts"
      |> where(title: parent_as(:comment).subtitle)
      |> select([r], r.title)
      |> subquery()

    query =
      "comments"
      |> from(as: :comment)
      |> join(:inner, [c], p in subquery(posts))
      |> select([_, p], p)
      |> plan()

    assert all(query) ==
             """
             SELECT s1.title \
             FROM comments AS c0 \
             INNER JOIN (\
             SELECT sp0.title AS title \
             FROM posts AS sp0 \
             WHERE (sp0.title = c0.subtitle)\
             ) AS s1 ON 1\
             """
  end

  test "join with prefix" do
    query =
      Schema
      |> join(:inner, [p], q in Schema2, on: p.x == q.z)
      |> select([], true)
      |> Map.put(:prefix, "prefix")
      |> plan()

    assert all(query) ==
             """
             SELECT 1 \
             FROM prefix.schema AS s0 \
             INNER JOIN prefix.schema2 AS s1 ON s0.x = s1.z\
             """

    query =
      Schema
      |> from(prefix: "first")
      |> join(:inner, [p], q in Schema2, on: p.x == q.z, prefix: "second")
      |> select([], true)
      |> Map.put(:prefix, "prefix")
      |> plan()

    assert all(query) ==
             """
             SELECT 1 \
             FROM first.schema AS s0 \
             INNER JOIN second.schema2 AS s1 ON s0.x = s1.z\
             """
  end

  test "join with fragment" do
    query =
      Schema
      |> join(
        :inner,
        [p],
        q in fragment(
          "SELECT * FROM schema2 AS s2 WHERE s2.id = ? AND s2.field = ?",
          p.x,
          ^10
        )
      )
      |> select([p], {p.id, ^0})
      |> where([p], p.id > 0 and p.id < ^100)
      |> plan()

    assert all(query) ==
             """
             SELECT s0.id, ? \
             FROM schema AS s0 \
             INNER JOIN \
             (\
             SELECT * \
             FROM schema2 AS s2 \
             WHERE s2.id = s0.x AND s2.field = ?\
             ) AS f1 ON 1 \
             WHERE ((s0.id > 0) AND (s0.id < ?))\
             """
  end

  test "join with fragment and on defined" do
    query =
      Schema
      |> join(:inner, [p], q in fragment("SELECT * FROM schema2"), on: q.id == p.id)
      |> select([p], {p.id, ^0})
      |> plan()

    assert all(query) ==
             """
             SELECT s0.id, ? \
             FROM schema AS s0 \
             INNER JOIN \
             (SELECT * FROM schema2) AS f1 ON f1.id = s0.id\
             """
  end

  test "join with query interpolation" do
    inner = Ecto.Queryable.to_query(Schema2)

    query =
      (p in Schema)
      |> from(left_join: c in ^inner, select: {p.id, c.id})
      |> plan()

    assert all(query) ==
             """
             SELECT s0.id, s1.id \
             FROM schema AS s0 \
             LEFT OUTER JOIN schema2 AS s1 ON 1\
             """
  end

  test "cross join" do
    query =
      (p in Schema)
      |> from(cross_join: c in Schema2, select: {p.id, c.id})
      |> plan()

    assert all(query) ==
             """
             SELECT s0.id, s1.id \
             FROM schema AS s0 \
             CROSS JOIN schema2 AS s1\
             """
  end

  test "join produces correct bindings" do
    query = from(p in Schema, join: c in Schema2, on: true)
    query = from(p in query, join: c in Schema2, on: true, select: {p.id, c.id})
    query = plan(query)

    assert all(query) ==
             """
             SELECT s0.id, s2.id \
             FROM schema AS s0 \
             INNER JOIN schema2 AS s1 ON 1 \
             INNER JOIN schema2 AS s2 ON 1\
             """
  end

  describe "query interpolation parameters" do
    test "self join on subquery" do
      subquery = select(Schema, [r], %{x: r.x, y: r.y})

      query =
        subquery
        |> join(:inner, [c], p in subquery(subquery))
        |> plan()
        |> all()

      assert query ==
               """
               SELECT s0.x, s0.y \
               FROM schema AS s0 \
               INNER JOIN (SELECT ss0.x AS x, ss0.y AS y FROM schema AS ss0) \
               AS s1 ON 1\
               """
    end

    test "self join on subquery with fragment" do
      subquery = select(Schema, [r], %{string: fragment("downcase(?)", ^"string")})

      query =
        subquery
        |> join(:inner, [c], p in subquery(subquery))
        |> plan()
        |> all()

      assert query ==
               """
               SELECT downcase(?) \
               FROM schema AS s0 \
               INNER JOIN (SELECT downcase(?) AS string FROM schema AS ss0) \
               AS s1 ON 1\
               """
    end

    test "join on subquery with simple select" do
      subquery = select(Schema, [r], %{x: ^999, w: ^888})

      query =
        Schema
        |> select([r], %{y: ^666})
        |> join(:inner, [c], p in subquery(subquery))
        |> where([a, b], a.x == ^111)
        |> plan()
        |> all()

      assert query ==
               """
               SELECT ? \
               FROM schema AS s0 \
               INNER JOIN (SELECT ? AS x, ? AS w FROM schema AS ss0) AS s1 ON 1 \
               WHERE (s0.x = ?)\
               """
    end
  end

  ##
  ## Associations
  ##

  test "association join belongs_to" do
    query =
      Schema2
      |> join(:inner, [c], p in assoc(c, :post))
      |> select([], true)
      |> plan()

    assert all(query) ==
             """
             SELECT 1 \
             FROM schema2 AS s0 \
             INNER JOIN schema AS s1 ON s1.x = s0.z\
             """
  end

  test "association join has_many" do
    query =
      Schema
      |> join(:inner, [p], c in assoc(p, :comments))
      |> select([], true)
      |> plan()

    assert all(query) ==
             """
             SELECT 1 \
             FROM schema AS s0 \
             INNER JOIN schema2 AS s1 ON s1.z = s0.x\
             """
  end

  test "association join has_one" do
    query =
      Schema
      |> join(:inner, [p], pp in assoc(p, :permalink))
      |> select([], true)
      |> plan()

    assert all(query) ==
             """
             SELECT 1 \
             FROM schema AS s0 \
             INNER JOIN schema3 AS s1 ON s1.id = s0.y\
             """
  end

  ##
  ## Schema based
  ##

  test "insert" do
    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:raise, [], []}, [])
    assert query == ~s{INSERT INTO schema (x,y) VALUES (?,?)}

    assert_raise(
      ArgumentError,
      "Cell-wise default values are not supported on INSERT statements by SQLite3",
      fn ->
        insert(
          nil,
          "schema",
          [:x, :y],
          [[:x, :y], [nil, :z]],
          {:raise, [], []},
          []
        )
      end
    )

    query = insert(nil, "schema", [], [[]], {:raise, [], []}, [])
    assert query == ~s{INSERT INTO schema DEFAULT VALUES}

    query = insert("prefix", "schema", [], [[]], {:raise, [], []}, [])
    assert query == ~s{INSERT INTO prefix.schema DEFAULT VALUES}

    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:raise, [], []}, [:id])
    assert query == ~s{INSERT INTO schema (x,y) VALUES (?,?) RETURNING id}

    assert_raise(
      ArgumentError,
      "Cell-wise default values are not supported on INSERT statements by SQLite3",
      fn ->
        insert(nil, "schema", [:x, :y], [[:x, :y], [nil, :z]], {:raise, [], []}, [:id])
      end
    )
  end

  test "insert with on conflict" do
    # These tests are adapted from the Postgres Adaptor

    # For :nothing
    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:nothing, [], []}, [])

    assert query ==
             """
             INSERT INTO schema (x,y) \
             VALUES (?,?) \
             ON CONFLICT DO NOTHING\
             """

    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:nothing, [], [:x, :y]}, [])

    assert query ==
             """
             INSERT INTO schema (x,y) \
             VALUES (?,?) \
             ON CONFLICT (x,y) DO NOTHING\
             """

    # For :update
    # update =
    #   from("schema", update: [set: [z: "foo"]])
    #   |> plan(:update_all)
    #   |> all()
    # query = insert(nil, "schema", [:x, :y], [[:x, :y]], {update, [], [:x, :y]}, [:z])
    # assert query == ~s{INSERT INTO schema (x,y) VALUES (?,?) ON CONFLICT (x,y) DO UPDATE SET z = 'foo'}

    # update =
    #   from("schema", update: [set: [z: ^"foo"]], where: [w: true])
    #   |> plan(:update_all)
    #   |> all()
    # query = insert(nil, "schema", [:x, :y], [[:x, :y]], {update, [], [:x, :y]}, [:z])
    # assert query =  ~s{INSERT INTO schema (x,y) VALUES (?,?) ON CONFLICT (x,y) DO UPDATE SET z = ? WHERE (schema.w = 1)}

    # update =
    #   from("schema", update: [set: [z: "foo"]])
    #   |> plan(:update_all)
    #   |> all()
    # query = insert(nil, "schema", [:x, :y], [[:x, :y]], {update, [], [:x, :y]}, [:z])
    # assert query = ~s{INSERT INTO schema (x,y) VALUES (?,?) ON CONFLICT (x,y) DO UPDATE SET z = 'foo'}

    # update =
    #   from("schema", update: [set: [z: ^"foo"]], where: [w: true])
    #   |> plan(:update_all)
    #   |> all()
    # query = insert(nil, "schema", [:x, :y], [[:x, :y]], {update, [], [:x, :y]}, [:z])
    # assert query = ~s{INSERT INTO schema (x,y) VALUES (?,?) ON CONFLICT (x,y) DO UPDATE SET z = ? WHERE (schema.w = 1)}

    # For :replace_all
    assert_raise(
      ArgumentError,
      "Upsert in SQLite3 requires :conflict_target",
      fn ->
        conflict_target = []

        insert(
          nil,
          "schema",
          [:x, :y],
          [[:x, :y]],
          {:replace_all, [], conflict_target},
          []
        )
      end
    )

    assert_raise(
      ArgumentError,
      "Upsert in SQLite3 does not support ON CONSTRAINT",
      fn ->
        insert(
          nil,
          "schema",
          [:x, :y],
          [[:x, :y]],
          {:replace_all, [], {:constraint, :foo}},
          []
        )
      end
    )

    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:replace_all, [], [:id]}, [])

    assert query ==
             """
             INSERT INTO schema (x,y) \
             VALUES (?,?) \
             ON CONFLICT (id) \
             DO UPDATE SET x = EXCLUDED.x,y = EXCLUDED.y\
             """
  end

  test "insert with query" do
    select_query = from("schema", select: [:id]) |> plan(:all)

    assert_raise(
      ArgumentError,
      "Cell-wise default values are not supported on INSERT statements by SQLite3",
      fn ->
        insert(
          nil,
          "schema",
          [:x, :y, :z],
          [[:x, {select_query, 2}, :z], [nil, nil, {select_query, 1}]],
          {:raise, [], []},
          []
        )
      end
    )
  end

  test "insert with query as rows" do
    query = from(s in "schema", select: %{ foo: fragment("3"), bar: s.bar }) |> plan(:all)
    query = insert(nil, "schema", [:foo, :bar], query, {:raise, [], []}, [])

    assert query == ~s{INSERT INTO schema (foo,bar) (SELECT 3, s0.bar FROM schema AS s0)}
  end

  # test "update" do
  #   query = update(nil, "schema", [:x, :y], [:id], [])
  #   assert query == ~s{UPDATE schema SET x = ?, y = ? WHERE id = ?}
  #
  #   query = update(nil, "schema", [:x, :y], [:id], [])
  #   assert query == ~s{UPDATE schema SET x = ?, y = ? WHERE id = ?}
  #
  #   query = update("prefix", "schema", [:x, :y], [:id], [])
  #   assert query == ~s{UPDATE prefix.schema SET x = ?, y = ? WHERE id = ?}
  # end

  test "delete" do
    query = delete(nil, "schema", [x: 1, y: 2], [])
    assert query == ~s{DELETE FROM schema WHERE x = ? AND y = ?}

    query = delete("prefix", "schema", [x: 1, y: 2], [])
    assert query == ~s{DELETE FROM prefix.schema WHERE x = ? AND y = ?}

    query = delete(nil, "schema", [x: nil, y: 1], [])
    assert query == ~s{DELETE FROM schema WHERE x IS NULL AND y = ?}
  end

  ##
  ## DDL
  ##

  test "executing a string during migration" do
    assert execute_ddl("example") == ["example"]
  end

  test "create table" do
    create =
      {:create, table(:posts),
       [
         {:add, :name, :string, [default: "Untitled", size: 20, null: false]},
         {:add, :token, :binary, [size: 20, null: false]},
         {:add, :price, :numeric,
          [precision: 8, scale: 2, default: {:fragment, "expr"}]},
         {:add, :on_hand, :integer, [default: 0, null: true]},
         {:add, :likes, :integer, [default: 0, null: false]},
         {:add, :published_at, :datetime, [null: true]},
         {:add, :is_active, :boolean, [default: true]}
       ]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE posts (\
             name TEXT DEFAULT 'Untitled' NOT NULL, \
             token BLOB NOT NULL, \
             price NUMERIC DEFAULT expr, \
             on_hand INTEGER DEFAULT 0 NULL, \
             likes INTEGER DEFAULT 0 NOT NULL, \
             published_at DATETIME NULL, \
             is_active BOOLEAN DEFAULT true\
             )\
             """
           ]
  end

  test "create empty table" do
    create = {:create, table(:posts), []}

    assert execute_ddl(create) == ["CREATE TABLE posts ()"]
  end

  test "create table with prefix" do
    create =
      {:create, table(:posts, prefix: :foo),
       [{:add, :category_0, %Reference{table: :categories}, []}]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE foo.posts (\
             category_0 INTEGER CONSTRAINT posts_category_0_fkey REFERENCES foo.categories(id)\
             )\
             """
           ]
  end

  test "create table with references" do
    create =
      {:create, table(:posts),
       [
         {:add, :id, :serial, [primary_key: true]},
         {:add, :category_0, %Reference{table: :categories}, []},
         {:add, :category_1, %Reference{table: :categories, name: :foo_bar}, []},
         {:add, :category_2, %Reference{table: :categories, on_delete: :nothing}, []},
         {:add, :category_3, %Reference{table: :categories, on_delete: :delete_all},
          [null: false]},
         {:add, :category_4, %Reference{table: :categories, on_delete: :nilify_all},
          []},
         {:add, :category_5,
          %Reference{table: :categories, prefix: :foo, on_delete: :nilify_all}, []},
         {:add, :category_6,
          %Reference{table: :categories, with: [here: :there], on_delete: :nilify_all},
          []},
         {:add, :category_7,
          %Reference{table: :tags, with: [that: :this], on_delete: :nilify_all},
          []},
       ]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE posts (\
             id INTEGER PRIMARY KEY AUTOINCREMENT, \
             category_0 INTEGER CONSTRAINT posts_category_0_fkey REFERENCES categories(id), \
             category_1 INTEGER CONSTRAINT foo_bar REFERENCES categories(id), \
             category_2 INTEGER CONSTRAINT posts_category_2_fkey REFERENCES categories(id), \
             category_3 INTEGER NOT NULL CONSTRAINT posts_category_3_fkey REFERENCES categories(id) ON DELETE CASCADE, \
             category_4 INTEGER CONSTRAINT posts_category_4_fkey REFERENCES categories(id) ON DELETE SET NULL, \
             category_5 INTEGER CONSTRAINT posts_category_5_fkey REFERENCES foo.categories(id) ON DELETE SET NULL, \
             category_6 INTEGER, \
             category_7 INTEGER, \
             FOREIGN KEY (category_6,here) REFERENCES categories(id,there) ON DELETE SET NULL, \
             FOREIGN KEY (category_7,that) REFERENCES tags(id,this) ON DELETE SET NULL\
             )\
             """
           ]
  end

  test "create table with options" do
    assert_raise(
      ArgumentError,
      "SQLite3 adapter does not support keyword lists in :options",
      fn ->
        {:create, table(:posts, options: "WITH FOO=BAR"),
         [{:add, :id, :serial, [primary_key: true]}, {:add, :created_at, :datetime, []}]}
        |> execute_ddl()
      end
    )
  end

  test "create table with composite key" do
    create =
      {:create, table(:posts),
       [
         {:add, :a, :integer, [primary_key: true]},
         {:add, :b, :integer, [primary_key: true]},
         {:add, :name, :string, []}
       ]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE posts (\
             a INTEGER, \
             b INTEGER, \
             name TEXT, \
             PRIMARY KEY (a, b)\
             )\
             """
           ]
  end

  test "create table with a map column, and a map default with values" do
    create =
      {:create, table(:posts),
       [
         {:add, :a, :map, [default: %{foo: "bar", baz: "boom"}]}
       ]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE posts (a JSON DEFAULT ('{\"baz\":\"boom\",\"foo\":\"bar\"}'))\
             """
           ]
  end

  test "create table with time columns" do
    create =
      {:create, table(:posts),
       [{:add, :published_at, :time, [precision: 3]}, {:add, :submitted_at, :time, []}]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE posts (\
             published_at TIME, \
             submitted_at TIME\
             )\
             """
           ]
  end

  test "create table with utc_datetime columns" do
    create =
      {:create, table(:posts),
       [
         {:add, :published_at, :utc_datetime, [precision: 3]},
         {:add, :submitted_at, :utc_datetime, []}
       ]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE posts (\
             published_at TEXT_DATETIME, \
             submitted_at TEXT_DATETIME\
             )\
             """
           ]
  end

  test "create table with naive_datetime columns" do
    create =
      {:create, table(:posts),
       [
         {:add, :published_at, :naive_datetime, [precision: 3]},
         {:add, :submitted_at, :naive_datetime, []}
       ]}

    assert execute_ddl(create) == [
             "CREATE TABLE posts (published_at TEXT_DATETIME, submitted_at TEXT_DATETIME)"
           ]
  end

  test "create table with an unsupported type" do
    assert_raise(
      ArgumentError,
      "argument error",
      fn ->
        {:create, table(:posts),
         [
           {:add, :a, {:a, :b, :c}, [default: %{}]}
         ]}
        |> execute_ddl()
      end
    )
  end

  test "drop table" do
    drop = {:drop, table(:posts)}

    assert execute_ddl(drop) == [~s|DROP TABLE posts|]
  end

  test "drop table with prefixes" do
    drop = {:drop, table(:posts, prefix: :foo)}

    assert execute_ddl(drop) == [~s|DROP TABLE foo.posts|]
  end

  test "drop constraint" do
    assert_raise(
      ArgumentError,
      ~r/ALTER TABLE with constraints not supported by SQLite3/,
      fn ->
        execute_ddl(
          {:drop, constraint(:products, "price_must_be_positive", prefix: :foo)}
        )
      end
    )
  end

  test "drop_if_exists constraint" do
    assert_raise(
      ArgumentError,
      ~r/SQLite3 adapter does not support constraints/,
      fn ->
        execute_ddl(
          {:drop_if_exists,
           constraint(:products, "price_must_be_positive", prefix: :foo)}
        )
      end
    )
  end

  test "alter table" do
    alter =
      {:alter, table(:posts),
       [
         {:add, :title, :string, [default: "Untitled", size: 100, null: false]},
         {:add, :author_id, %Reference{table: :author}, []}
       ]}

    assert execute_ddl(alter) == [
             """
             ALTER TABLE posts \
             ADD COLUMN title TEXT DEFAULT 'Untitled' NOT NULL\
             """,
             """
             ALTER TABLE posts \
             ADD COLUMN author_id INTEGER CONSTRAINT posts_author_id_fkey REFERENCES author(id)\
             """
           ]
  end

  test "alter table with datetime not null" do
    alter =
      {:alter, table(:posts),
       [
         {:add, :title, :string, [default: "Untitled", size: 100, null: false]},
         {:add, :when, :utc_datetime, [null: false]}
       ]}

    assert execute_ddl(alter) == [
             """
             ALTER TABLE posts \
             ADD COLUMN title TEXT DEFAULT 'Untitled' NOT NULL\
             """,
             """
             ALTER TABLE posts \
             ADD COLUMN when TEXT_DATETIME\
             """
           ]
  end

  test "alter table with prefix" do
    alter =
      {:alter, table(:posts, prefix: :foo),
       [
         {:add, :title, :string, [default: "Untitled", size: 100, null: false]},
         {:add, :author_id, %Reference{table: :author}, []}
       ]}

    assert execute_ddl(alter) == [
             """
             ALTER TABLE foo.posts \
             ADD COLUMN title TEXT DEFAULT 'Untitled' NOT NULL\
             """,
             """
             ALTER TABLE foo.posts \
             ADD COLUMN author_id INTEGER \
             CONSTRAINT posts_author_id_fkey REFERENCES foo.author(id)\
             """
           ]
  end

  test "alter column errors for :modify column" do
    assert_raise(
      ArgumentError,
      "ALTER COLUMN not supported by SQLite3",
      fn ->
        {:alter, table(:posts),
         [
           {:modify, :price, :numeric, [precision: 8, scale: 2]}
         ]}
        |> execute_ddl()
      end
    )
  end

  test "alter table removes column" do
    alteration = {
      :alter,
      table(:posts),
      [{:remove, :price, :numeric, [precision: 8, scale: 2]}]
    }

    assert execute_ddl(alteration) == [
      """
      ALTER TABLE posts \
      DROP COLUMN price\
      """
    ]
  end

  test "alter table with primary key" do
    alter = {:alter, table(:posts), [{:add, :my_pk, :serial, [primary_key: true]}]}

    assert execute_ddl(alter) == [
             """
             ALTER TABLE posts \
             ADD COLUMN my_pk INTEGER PRIMARY KEY AUTOINCREMENT\
             """
           ]
  end

  test "create index" do
    create = {:create, index(:posts, [:category_id, :permalink])}

    assert execute_ddl(create) ==
             [
               """
               CREATE INDEX posts_category_id_permalink_index \
               ON posts (category_id, permalink)\
               """
             ]

    create = {:create, index(:posts, ["lower(permalink)"], name: "posts$main")}

    assert execute_ddl(create) == [
             """
             CREATE INDEX posts$main ON posts (lower(permalink))\
             """
           ]
  end

  test "create index if not exists" do
    create = {:create_if_not_exists, index(:posts, [:category_id, :permalink])}
    query = execute_ddl(create)

    assert query == [
             """
             CREATE INDEX IF NOT EXISTS posts_category_id_permalink_index \
             ON posts (category_id, permalink)\
             """
           ]
  end

  test "create index with prefix" do
    create = {:create, index(:posts, [:category_id, :permalink], prefix: :foo)}

    assert execute_ddl(create) == [
             """
             CREATE INDEX posts_category_id_permalink_index \
             ON foo.posts (category_id, permalink)\
             """
           ]

    create =
      {:create, index(:posts, ["lower(permalink)"], name: "posts$main", prefix: :foo)}

    assert execute_ddl(create) == [
             """
             CREATE INDEX posts$main ON foo.posts (lower(permalink))\
             """
           ]
  end

  test "create index with comment" do
    create =
      {:create,
       index(:posts, [:category_id, :permalink], prefix: :foo, comment: "comment")}

    assert execute_ddl(create) == [
             """
             CREATE INDEX posts_category_id_permalink_index \
             ON foo.posts (category_id, permalink)\
             """
           ]

    # NOTE: Comments are not supported by SQLite. DDL query generator will ignore them.
  end

  test "create unique index" do
    create = {:create, index(:posts, [:permalink], unique: true)}

    assert execute_ddl(create) == [
             """
             CREATE UNIQUE INDEX posts_permalink_index \
             ON posts (permalink)\
             """
           ]
  end

  test "create unique index if not exists" do
    create = {:create_if_not_exists, index(:posts, [:permalink], unique: true)}
    query = execute_ddl(create)

    assert query == [
             """
             CREATE UNIQUE INDEX IF NOT EXISTS posts_permalink_index \
             ON posts (permalink)\
             """
           ]
  end

  test "create unique index with condition" do
    create = {:create, index(:posts, [:permalink], unique: true, where: "public IS 1")}

    assert execute_ddl(create) == [
             """
             CREATE UNIQUE INDEX posts_permalink_index \
             ON posts (permalink) WHERE public IS 1\
             """
           ]

    create = {:create, index(:posts, [:permalink], unique: true, where: :public)}

    assert execute_ddl(create) == [
             """
             CREATE UNIQUE INDEX posts_permalink_index \
             ON posts (permalink) WHERE public\
             """
           ]
  end

  test "create index concurrently" do
    # NOTE: SQLite doesn't support CONCURRENTLY, so this isn't included in generated SQL.
    create = {:create, index(:posts, [:permalink], concurrently: true)}

    assert execute_ddl(create) == [
             ~s|CREATE INDEX posts_permalink_index ON posts (permalink)|
           ]
  end

  test "create unique index concurrently" do
    # NOTE: SQLite doesn't support CONCURRENTLY, so this isn't included in generated SQL.
    create = {:create, index(:posts, [:permalink], concurrently: true, unique: true)}

    assert execute_ddl(create) == [
             ~s|CREATE UNIQUE INDEX posts_permalink_index ON posts (permalink)|
           ]
  end

  test "create an index using a different type" do
    # NOTE: SQLite doesn't support USING, so this isn't included in generated SQL.
    create = {:create, index(:posts, [:permalink], using: :hash)}

    assert execute_ddl(create) == [
             ~s|CREATE INDEX posts_permalink_index ON posts (permalink)|
           ]
  end

  test "drop index" do
    drop = {:drop, index(:posts, [:id], name: "posts$main")}
    assert execute_ddl(drop) == [~s|DROP INDEX posts$main|]
  end

  test "drop index with prefix" do
    drop = {:drop, index(:posts, [:id], name: "posts$main", prefix: :foo)}
    assert execute_ddl(drop) == [~s|DROP INDEX foo.posts$main|]
  end

  test "drop index if exists" do
    drop = {:drop_if_exists, index(:posts, [:id], name: "posts$main")}
    assert execute_ddl(drop) == [~s|DROP INDEX IF EXISTS posts$main|]
  end

  test "drop index concurrently" do
    # NOTE: SQLite doesn't support CONCURRENTLY, so this isn't included in generated SQL.
    drop = {:drop, index(:posts, [:id], name: "posts$main", concurrently: true)}
    assert execute_ddl(drop) == [~s|DROP INDEX posts$main|]
  end

  test "create check constraint" do
    assert_raise(
      ArgumentError,
      "ALTER TABLE with constraints not supported by SQLite3",
      fn ->
        {:create, constraint(:products, "price_must_be_positive", check: "price > 0")}
        |> execute_ddl()
      end
    )

    assert_raise(
      ArgumentError,
      "ALTER TABLE with constraints not supported by SQLite3",
      fn ->
        {:create,
         constraint(:products, "price_must_be_positive",
           check: "price > 0",
           prefix: "foo"
         )}
        |> execute_ddl()
      end
    )
  end

  test "create exclusion constraint" do
    assert_raise(
      ArgumentError,
      "ALTER TABLE with constraints not supported by SQLite3",
      fn ->
        {:create,
         constraint(:products, "price_must_be_positive",
           exclude: ~s|gist (int4range("from", "to", '[]') WITH &&)|
         )}
        |> execute_ddl()
      end
    )
  end

  test "create constraint with comment" do
    assert_raise(
      ArgumentError,
      "ALTER TABLE with constraints not supported by SQLite3",
      fn ->
        {:create,
         constraint(:products, "price_must_be_positive",
           check: "price > 0",
           prefix: "foo",
           comment: "comment"
         )}
        |> execute_ddl()
      end
    )
  end

  test "rename table" do
    rename = {:rename, table(:posts), table(:new_posts)}

    assert execute_ddl(rename) == [
             ~s|ALTER TABLE posts RENAME TO new_posts|
           ]
  end

  test "rename table with prefix" do
    rename = {:rename, table(:posts, prefix: :foo), table(:new_posts, prefix: :foo)}

    assert execute_ddl(rename) == [
             ~s|ALTER TABLE foo.posts RENAME TO new_posts|
           ]
  end

  test "rename column" do
    rename = {:rename, table(:posts), :given_name, :first_name}

    assert execute_ddl(rename) == [
             ~s|ALTER TABLE posts RENAME COLUMN given_name TO first_name|
           ]
  end

  test "rename column in prefixed table" do
    rename = {:rename, table(:posts, prefix: :foo), :given_name, :first_name}

    assert execute_ddl(rename) == [
             ~s|ALTER TABLE foo.posts RENAME COLUMN given_name TO first_name|
           ]
  end

  test "drop column" do
    drop_column = {:alter, table(:posts), [{:remove, :summary}]}

    assert execute_ddl(drop_column) == [
      """
      ALTER TABLE posts \
      DROP COLUMN summary\
      """
    ]
  end

  test "arrays" do
    assert_raise(
      Ecto.QueryError,
      ~r"Array type is not supported by SQLite3",
      fn ->
        Schema
        |> select([], fragment("?", [1, 2, 3]))
        |> plan()
        |> all()
      end
    )
  end

  test "preloading" do
    query =
      from(p in Post, preload: [:comments], select: p)
      |> plan()
      |> all()

    assert query == "SELECT p0.id, p0.title, p0.content FROM posts AS p0"
  end
end
