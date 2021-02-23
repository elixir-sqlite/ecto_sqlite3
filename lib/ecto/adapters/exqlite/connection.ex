defmodule Ecto.Adapters.Exqlite.Connection do
  @behaviour Ecto.Adapters.SQL.Connection

  alias Ecto.Migration.Constraint
  alias Ecto.Migration.Index
  alias Ecto.Migration.Reference
  alias Ecto.Migration.Table
  alias Ecto.Query.BooleanExpr
  alias Ecto.Query.JoinExpr
  alias Ecto.Query.QueryExpr
  alias Ecto.Query.WithExpr

  @parent_as __MODULE__

  @impl true
  def child_spec(opts) do
    {:ok, _} = Application.ensure_all_started(:db_connection)
    DBConnection.child_spec(Exqlite.Connection, opts)
  end

  @impl true
  def prepare_execute(conn, name, sql, params, opts) do
    query = %Exqlite.Query{name: name, statement: sql}

    case DBConnection.prepare_execute(conn, query, map_params(params), opts) do
      {:ok, _, _} = ok -> ok
      {:error, %Exqlite.Error{}} = error -> error
      {:error, err} -> raise err
    end
  end

  @impl true
  def execute(conn, %Exqlite.Query{} = cached, params, opts) do
    DBConnection.execute(conn, cached, params, opts)
  end

  @impl true
  def execute(conn, sql, params, opts) when is_binary(sql) or is_list(sql) do
    query = %Exqlite.Query{name: "", statement: IO.iodata_to_binary(sql)}

    case DBConnection.prepare_execute(conn, query, map_params(params), opts) do
      {:ok, %Exqlite.Query{}, result} -> {:ok, result}
      {:error, %Exqlite.Error{}} = error -> error
      {:error, err} -> raise err
    end
  end

  @impl true
  def execute(conn, query, params, opts) do
    case DBConnection.execute(conn, query, map_params(params), opts) do
      {:ok, _} = ok -> ok
      {:error, %ArgumentError{} = err} -> {:reset, err}
      {:error, %Exqlite.Error{}} = error -> error
      {:error, err} -> raise err
    end
  end

  @impl true
  def query(conn, sql, params, opts) do
    query = %Exqlite.Query{statement: sql}
    DBConnection.execute(conn, query, params, opts)
  end

  @impl true
  def stream(conn, sql, params, opts) do
    query = %Exqlite.Query{statement: sql}
    DBConnection.stream(conn, query, params, opts)
  end

  @impl true
  def to_constraints(_, _), do: []

  @impl true
  def all(%Ecto.Query{lock: lock}) when lock != nil do
    raise ArgumentError, "locks are not supported by SQLite"
  end

  @impl true
  def all(query, as_prefix \\ []) do
    sources = create_names(query, as_prefix)

    cte = cte(query, sources)
    from = from(query, sources)
    select = select(query, sources)
    join = join(query, sources)
    where = where(query, sources)
    group_by = group_by(query, sources)
    having = having(query, sources)
    window = window(query, sources)
    combinations = combinations(query)
    order_by = order_by(query, sources)
    limit = limit(query, sources)
    offset = offset(query, sources)

    [
      cte,
      select,
      from,
      join,
      where,
      group_by,
      having,
      window,
      combinations,
      order_by,
      limit,
      offset
    ]
  end

  @impl true
  def update_all(%Ecto.Query{joins: [_ | _]}) do
    # TODO: It is supported but not in the traditional sense
    raise ArgumentError, "JOINS are not supported on UPDATE statements by SQLite"
  end

  @impl true
  def update_all(query, prefix \\ nil) do
    %{from: %{source: source}, select: select} = query

    if select do
      raise ArgumentError, ":select is not supported in update_all by SQLite3"
    end

    sources = create_names(query, [])
    cte = cte(query, sources)
    {from, name} = get_source(query, sources, 0, source)

    fields =
      if prefix do
        update_fields(:on_conflict, query, sources)
      else
        update_fields(:update, query, sources)
      end

    {join, wheres} = using_join(query, :update_all, sources)
    prefix = prefix || ["UPDATE ", from, " AS ", name, join, " SET "]
    where = where(%{query | wheres: wheres ++ query.wheres}, sources)

    [cte, prefix, fields | where]
  end

  @impl true
  def delete_all(%Ecto.Query{joins: [_ | _]}) do
    # TODO: It is supported but not in the traditional sense
    raise ArgumentError, "JOINS are not supported on DELETE statements by SQLite"
  end

  @impl true
  def delete_all(query) do
    if query.select do
      raise ArgumentError, ":select is not supported in delete_all by SQLite3"
    end

    sources = create_names(query, [])
    cte = cte(query, sources)
    {_, name, _} = elem(sources, 0)

    from = from(query, sources)
    # TODO: joins are not supported, but we could alter the query to utilize
    #       from and where.
    # join = join(query, sources)
    where = where(query, sources)

    [cte, "DELETE ", name, ".*", from, where]
  end

  @impl true
  def insert(prefix, table, header, rows, on_conflict, returning) do
    insert(prefix, table, header, rows, on_conflict, returning, [])
  end

  def insert(prefix, table, header, rows, on_conflict, [], []) do
    fields = quote_names(header)

    [
      "INSERT INTO ",
      quote_table(prefix, table),
      " (",
      fields,
      ") VALUES ",
      insert_all(rows) | on_conflict(on_conflict, header)
    ]
  end

  def insert(_prefix, _table, _header, _rows, _on_conflict, returning, _placeholders)
    when length(returning) > 0
  do
    raise ArgumentError, ":returning is not supported in insert/6 by SQLite3"
  end

  def insert(_prefix, _table, _header, _rows, _on_conflict, _returning, placeholders)
    when length(placeholders) > 0
  do
    raise ArgumentError, ":placeholders is not supported insert/6 by SQLite3"
  end

  @impl true
  def update(_prefix, _table, _fields, _filters, returning)
    when length(returning) > 0
  do
    raise ArgumentError, ":returning is not supported in update/5 by SQLite3"
  end

  @impl true
  def update(prefix, table, fields, filters, []) do
    fields = intersperse_map(fields, ", ", &[quote_name(&1), " = ?"])

    filters =
      intersperse_map(filters, " AND ", fn
        {field, nil} ->
          [quote_name(field), " IS NULL"]

        {field, _value} ->
          [quote_name(field), " = ?"]
      end)

    ["UPDATE ", quote_table(prefix, table), " SET ", fields, " WHERE " | filters]
  end

  @impl true
  def delete(_prefix, _table, _filters, returning)
    when length(returning) > 0
  do
    raise ArgumentError, ":returning is not supported in delete/4 by SQLite3"
  end

  @impl true
  def delete(prefix, table, filters, []) do
    filters =
      intersperse_map(filters, " AND ", fn
        {field, nil} ->
          [quote_name(field), " IS NULL"]

        {field, _value} ->
          [quote_name(field), " = ?"]
      end)

    ["DELETE FROM ", quote_table(prefix, table), " WHERE " | filters]
  end

  @impl true
  def explain_query(conn, query, params, opts) do
    case query(conn, build_explain_query(query), params, opts) do
      {:ok, %Exqlite.Result{} = result} ->
        {:ok, SQL.format_table(result)}

      error ->
        error
    end
  end

  @impl true
  def execute_ddl({_command, %Table{options: keyword}, _}) when is_list(keyword) do
    raise ArgumentError, "SQLite3 adapter does not support keyword lists in :options"
  end

  @impl true
  def execute_ddl({:create, %Table{} = table, columns}) do
    {table, composite_pk_def} = composite_pk_definition(table, columns)

    [
      [
        "CREATE TABLE ",
        quote_table(table.prefix, table.name), ?\s, ?(,
        column_definitions(table, columns), composite_pk_def, ?),
        options_expr(table.options)
      ]
    ]
  end

  @impl true
  def execute_ddl({:create_if_not_exists, %Table{} = table, columns}) do
    {table, composite_pk_def} = composite_pk_definition(table, columns)

    [
      [
        "CREATE TABLE IF NOT EXISTS ",
        quote_table(table.prefix, table.name), ?\s, ?(,
        column_definitions(table, columns), composite_pk_def, ?),
        options_expr(table.options)
      ]
    ]
  end

  @impl true
  def execute_ddl({:drop, %Table{} = table}) do
    [
      [
        "DROP TABLE ",
        quote_table(table.prefix, table.name)
      ]
    ]
  end

  @impl true
  def execute_ddl({:drop_if_exists, %Table{} = table}) do
    [
      [
        "DROP TABLE IF EXISTS ",
        quote_table(table.prefix, table.name)
      ]
    ]
  end

  @impl true
  def execute_ddl({:alter, %Table{} = table, changes}) do
    Enum.map(changes, fn (change) ->
      ["ALTER TABLE ", quote_table(table.prefix, table.name), ?\s, column_change(table, change)]
    end)
  end

  @impl true
  def execute_ddl({command, %Index{} = index})
    when command in [:create, :create_if_not_exists]
  do
    fields = intersperse_map(index.columns, ", ", &index_expr/1)

    [
      [
        "CREATE ",
        if_do(index.unique, "UNIQUE "),
        "INDEX",
        if_do(command == :create_if_not_exists, " IF NOT EXISTS"),
        ?\s,
        quote_name(index.name),
        " ON ",
        quote_table(index.prefix, index.table),
        ?\s, ?(, fields, ?),
        if_do(index.where, [" WHERE ", to_string(index.where)])
      ]
    ]
  end

  @impl true
  def execute_ddl({:drop, %Index{} = index}) do
    [
      [
        "DROP INDEX ",
        quote_table(index.prefix, index.name)
      ]
    ]
  end

  @impl true
  def execute_ddl({:drop_if_exists, %Index{} = index}) do
    [
      [
        "DROP INDEX IF EXISTS",
        quote_table(index.prefix, index.name)
      ]
    ]
  end

  @impl true
  def execute_ddl({:rename, %Table{} = current_table, %Table{} = new_table}) do
    [
      [
        "ALTER TABLE ",
        quote_table(current_table.prefix, current_table.name),
        " RENAME TO ",
        quote_table(nil, new_table.name)
      ]
    ]
  end

  @impl true
  def execute_ddl({:rename, %Table{} = current_table, old_col, new_col}) do
    [
      [
        "ALTER TABLE ",
        quote_table(current_table.prefix, current_table.name),
        " RENAME COLUMN ",
        quote_name(old_col),
        " TO ",
        quote_name(new_col)
      ]
    ]
  end

  @impl true
  def execute_ddl({:create, %Constraint{}}) do
    raise ArgumentError, "ALTER TABLE with constraints not supported by SQLite3"
  end

  @impl true
  def execute_ddl({:drop, %Constraint{}}) do
    raise ArgumentError, "ALTER TABLE with constraints not supported by SQLite3"
  end

  @impl true
  def execute_ddl(string) when is_binary(string), do: [string]

  @impl true
  def execute_ddl(keyword) when is_list(keyword) do
    raise ArgumentError, "SQLite3 adapter does not support keyword lists in execute"
  end

  @impl true
  def execute_ddl({:create, %Index{} = index}) do
    fields = intersperse_map(index.columns, ", ", &index_expr/1)

    [
      [
        "CREATE ",
        if_do(index.unique, "UNIQUE "),
        "INDEX",
        ?\s,
        quote_name(index.name),
        " ON ",
        quote_table(index.prefix, index.table),
        ?\s,
        ?(,
        fields,
        ?),
        if_do(index.where, [" WHERE ", to_string(index.where)])
      ]
    ]
  end

  @impl true
  def execute_ddl({:create_if_not_exists, %Index{} = index}) do
    fields = intersperse_map(index.columns, ", ", &index_expr/1)

    [
      [
        "CREATE ",
        if_do(index.unique, "UNIQUE "),
        "INDEX IF NOT EXISTS",
        ?\s,
        quote_name(index.name),
        " ON ",
        quote_table(index.prefix, index.table),
        ?\s,
        ?(,
        fields,
        ?),
        if_do(index.where, [" WHERE ", to_string(index.where)])
      ]
    ]
  end

  @impl true
  def execute_ddl({:create, %Constraint{check: check}}) when is_binary(check) do
    raise ArgumentError, "SQLite3 adapter does not support check constraints"
  end

  @impl true
  def execute_ddl({:create, %Constraint{exclude: exclude}}) when is_binary(exclude) do
    raise ArgumentError, "SQLite3 adapter does not support exclusion constraints"
  end

  @impl true
  def execute_ddl({:drop, %Index{} = index}) do
    [
      [
        "DROP INDEX ",
        quote_table(index.prefix, index.name)
      ]
    ]
  end

  @impl true
  def execute_ddl({:drop_if_exists, %Index{} = index}) do
    [
      [
        "DROP INDEX IF EXISTS ",
        quote_table(index.prefix, index.name)
      ]
    ]
  end

  @impl true
  def execute_ddl({:drop, %Constraint{}}) do
    raise ArgumentError, "SQLite3 adapter does not support constraints"
  end

  @impl true
  def execute_ddl({:drop_if_exists, %Constraint{}}) do
    raise ArgumentError, "SQLite3 adapter does not support constraints"
  end

  @impl true
  def execute_ddl({:rename, %Table{} = current_table, %Table{} = new_table}) do
    [
      [
        "ALTER TABLE ",
        quote_table(current_table.prefix, current_table.name),
        " RENAME TO ",
        quote_table(new_table.prefix, new_table.name)
      ]
    ]
  end

  @impl true
  def execute_ddl({:rename, %Table{} = table, current_column, new_column}) do
    [
      [
        "ALTER TABLE ",
        quote_table(table.prefix, table.name),
        " RENAME COLUMN ",
        quote_name(current_column),
        " TO ",
        quote_name(new_column)
      ]
    ]
  end

  @impl true
  def execute_ddl(string) when is_binary(string), do: [string]

  @impl true
  def execute_ddl(keyword) when is_list(keyword) do
    raise ArgumentError, "SQLite3 adapter does not support keyword lists in execute"
  end

  @impl true
  def ddl_logs(_), do: []

  @impl true
  def table_exists_query(table) do
    {"SELECT name FROM sqlite_master WHERE type='table' AND name=? LIMIT 1", [table]}
  end

  defp map_params(params) do
    Enum.map(params, fn
      %{__struct__: _} = data_type ->
        {:ok, value} = Ecto.DataType.dump(data_type)
        value

      %{} = value ->
        Ecto.Adapter.json_library().encode!(value)

      value when is_list(value) ->
        Ecto.Adapter.json_library().encode!(value)

      value ->
        value
    end)
  end

  def build_explain_query(query) do
    IO.iodata_to_binary(["EXPLAIN ", query])
  end

  ##
  ## Query generation
  ##

  # defp strip_quotes(quoted) do
  #   size = byte_size(quoted) - 2
  #   <<_, unquoted::binary-size(size), _>> = quoted
  #   unquoted
  # end

  # defp normalize_index_name(quoted, source) do
  #   name = strip_quotes(quoted)
  #
  #   if source do
  #     String.trim_leading(name, "#{source}.")
  #   else
  #     name
  #   end
  # end

  def on_conflict({:raise, _, []}, _header), do: []

  def on_conflict({:nothing, _, targets}, _header) do
    [" ON CONFLICT ", conflict_target(targets) | "DO NOTHING"]
  end

  def on_conflict({:replace_all, _, []}, _header) do
    raise(ArgumentError, "Upsert in SQLite requires :conflict_target")
  end

  def on_conflict({:replace_all, _, {:constraint, _}}, _header) do
    raise(ArgumentError, "Upsert in SQLite does not support ON CONSTRAINT")
  end

  def on_conflict({:replace_all, _, targets}, header) do
    [" ON CONFLICT ", conflict_target(targets), "DO " | replace_all(header)]
  end

  def on_conflict({query, _, targets}, _header) do
    [
      " ON CONFLICT ",
      conflict_target(targets),
      "DO " | update_all(query, "UPDATE SET ")
    ]
  end

  def conflict_target([]), do: ""

  def conflict_target(targets) do
    [?(, intersperse_map(targets, ?,, &quote_name/1), ?), ?\s]
  end

  def replace_all(header) do
    [
      "UPDATE SET "
      | intersperse_map(header, ?,, fn field ->
          quoted = quote_name(field)
          [quoted, " = ", "EXCLUDED." | quoted]
        end)
    ]
  end

  def insert_all(rows) do
    intersperse_map(rows, ?,, fn row ->
      [?(, intersperse_map(row, ?,, &insert_all_value/1), ?)]
    end)
  end

  def insert_all_value(nil), do: "DEFAULT"
  def insert_all_value({%Ecto.Query{} = query, _params_counter}), do: [?(, all(query), ?)]
  def insert_all_value(_), do: '?'

  binary_ops = [
    ==: " = ",
    !=: " != ",
    <=: " <= ",
    >=: " >= ",
    <: " < ",
    >: " > ",
    +: " + ",
    -: " - ",
    *: " * ",
    /: " / ",
    and: " AND ",
    or: " OR ",
    like: " LIKE "
  ]

  @binary_ops Keyword.keys(binary_ops)

  Enum.map(binary_ops, fn {op, str} ->
    def handle_call(unquote(op), 2), do: {:binary_op, unquote(str)}
  end)

  def handle_call(fun, _arity), do: {:fun, Atom.to_string(fun)}

  def select(%{select: %{fields: fields}, distinct: distinct} = query, sources) do
    ["SELECT ", distinct(distinct, sources, query) | select(fields, sources, query)]
  end

  def distinct(nil, _sources, _query), do: []
  def distinct(%QueryExpr{expr: true}, _sources, _query), do: "DISTINCT "
  def distinct(%QueryExpr{expr: false}, _sources, _query), do: []

  def distinct(%QueryExpr{expr: exprs}, _sources, query) when is_list(exprs) do
    error!(query, "DISTINCT with multiple columns is not supported by SQLite3")
  end

  defp select([], _sources, _query), do: "TRUE"

  defp select(fields, sources, query) do
    intersperse_map(fields, ", ", fn
      {:&, _, [idx]} ->
        case elem(sources, idx) do
          {source, _, nil} ->
            error!(
              query,
              "SQLite3 does not support selecting all fields from #{source} without a schema. " <>
                "Please specify a schema or specify exactly which fields you want to select"
            )

          {_, source, _} ->
            source
        end

      {key, value} ->
        [expr(value, sources, query), " AS ", quote_name(key)]

      value ->
        expr(value, sources, query)
    end)
  end

  def from(%{from: %{source: source}} = query, sources) do
    {from, name} = get_source(query, sources, 0, source)
    [" FROM ", from, " AS ", name]
  end

  def cte(
         %{with_ctes: %WithExpr{recursive: recursive, queries: [_ | _] = queries}} =
           query,
         sources
       ) do
    recursive_opt = if recursive, do: "RECURSIVE ", else: ""
    ctes = intersperse_map(queries, ", ", &cte_expr(&1, sources, query))
    ["WITH ", recursive_opt, ctes, " "]
  end

  def cte(%{with_ctes: _}, _), do: []

  defp cte_expr({name, cte}, sources, query) do
    [quote_name(name), " AS ", cte_query(cte, sources, query)]
  end

  defp cte_query(%Ecto.Query{} = query, _, _), do: ["(", all(query), ")"]
  defp cte_query(%QueryExpr{expr: expr}, sources, query), do: expr(expr, sources, query)

  defp update_fields(type, %{updates: updates} = query, sources) do
    fields =
      for(
        %{expr: expr} <- updates,
        {op, kw} <- expr,
        {key, value} <- kw,
        do: update_op(op, update_key(type, key, query, sources), value, sources, query)
      )

    Enum.intersperse(fields, ", ")
  end

  defp update_key(:update, key, %{from: from} = query, sources) do
    {_from, name} = get_source(query, sources, 0, from)

    [name, ?. | quote_name(key)]
  end

  defp update_key(:on_conflict, key, _query, _sources) do
    quote_name(key)
  end

  defp update_op(:set, quoted_key, value, sources, query) do
    [quoted_key, " = " | expr(value, sources, query)]
  end

  defp update_op(:inc, quoted_key, value, sources, query) do
    [quoted_key, " = ", quoted_key, " + " | expr(value, sources, query)]
  end

  defp update_op(command, _quoted_key, _value, _sources, query) do
    error!(query, "Unknown update operation #{inspect(command)} for SQLite3")
  end

  defp using_join(%{joins: []}, _kind, _sources), do: {[], []}

  defp using_join(%{joins: joins} = query, kind, sources) do
    froms =
      intersperse_map(joins, ", ", fn
        %JoinExpr{qual: :inner, ix: ix, source: source} ->
          {join, name} = get_source(query, sources, ix, source)
          [join, " AS " | name]

        %JoinExpr{qual: qual} ->
          error!(
            query,
            "SQLite3 adapter supports only inner joins on #{kind}, got: `#{qual}`"
          )
      end)

    wheres =
      for %JoinExpr{on: %QueryExpr{expr: value} = expr} <- joins,
          value != true,
          do: expr |> Map.put(:__struct__, BooleanExpr) |> Map.put(:op, :and)

    {[?,, ?\s | froms], wheres}
  end

  def join(%{joins: []}, _sources), do: []

  def join(%{joins: joins} = query, sources) do
    Enum.map(joins, fn
      %JoinExpr{
        on: %QueryExpr{expr: expr},
        qual: qual,
        ix: ix,
        source: source,
      } ->
        {join, name} = get_source(query, sources, ix, source)

        [
          join_qual(qual, query),
          join,
          " AS ",
          name,
          join_on(qual, expr, sources, query)
        ]
    end)
  end

  defp join_on(:cross, true, _sources, _query), do: []
  defp join_on(_qual, expr, sources, query), do: [" ON " | expr(expr, sources, query)]

  defp join_qual(:inner, _), do: " INNER JOIN "
  defp join_qual(:left, _), do: " LEFT OUTER JOIN "
  defp join_qual(:right, _), do: " RIGHT OUTER JOIN "
  defp join_qual(:full, _), do: " FULL OUTER JOIN "
  defp join_qual(:cross, _), do: " CROSS JOIN "

  defp join_qual(mode, q) do
    error!(q, "join `#{inspect(mode)}` not supported by SQLite3")
  end

  def where(%{wheres: wheres} = query, sources) do
    boolean(" WHERE ", wheres, sources, query)
  end

  def having(%{havings: havings} = query, sources) do
    boolean(" HAVING ", havings, sources, query)
  end

  def group_by(%{group_bys: []}, _sources), do: []

  def group_by(%{group_bys: group_bys} = query, sources) do
    [
      " GROUP BY "
      | intersperse_map(group_bys, ", ", fn %QueryExpr{expr: expr} ->
          intersperse_map(expr, ", ", &expr(&1, sources, query))
        end)
    ]
  end

  def window(%{windows: []}, _sources), do: []

  def window(%{windows: windows} = query, sources) do
    [
      " WINDOW "
      | intersperse_map(windows, ", ", fn {name, %{expr: kw}} ->
          [quote_name(name), " AS " | window_exprs(kw, sources, query)]
        end)
    ]
  end

  defp window_exprs(kw, sources, query) do
    [?(, intersperse_map(kw, ?\s, &window_expr(&1, sources, query)), ?)]
  end

  defp window_expr({:partition_by, fields}, sources, query) do
    ["PARTITION BY " | intersperse_map(fields, ", ", &expr(&1, sources, query))]
  end

  defp window_expr({:order_by, fields}, sources, query) do
    ["ORDER BY " | intersperse_map(fields, ", ", &order_by_expr(&1, sources, query))]
  end

  defp window_expr({:frame, {:fragment, _, _} = fragment}, sources, query) do
    expr(fragment, sources, query)
  end

  def order_by(%{order_bys: []}, _sources), do: []

  def order_by(%{order_bys: order_bys} = query, sources) do
    [
      " ORDER BY "
      | intersperse_map(order_bys, ", ", fn %QueryExpr{expr: expr} ->
          intersperse_map(expr, ", ", &order_by_expr(&1, sources, query))
        end)
    ]
  end

  defp order_by_expr({dir, expr}, sources, query) do
    str = expr(expr, sources, query)

    case dir do
      :asc -> str
      :desc -> [str | " DESC"]
      _ -> error!(query, "#{dir} is not supported in ORDER BY in SQLite3")
    end
  end

  def limit(%{limit: nil}, _sources), do: []

  def limit(%{limit: %QueryExpr{expr: expr}} = query, sources) do
    [" LIMIT " | expr(expr, sources, query)]
  end

  def offset(%{offset: nil}, _sources), do: []

  def offset(%{offset: %QueryExpr{expr: expr}} = query, sources) do
    [" OFFSET " | expr(expr, sources, query)]
  end

  defp combinations(%{combinations: combinations}) do
    Enum.map(combinations, fn
      {:union, query} -> [" UNION (", all(query), ")"]
      {:union_all, query} -> [" UNION ALL (", all(query), ")"]
      {:except, query} -> [" EXCEPT (", all(query), ")"]
      {:except_all, query} -> [" EXCEPT ALL (", all(query), ")"]
      {:intersect, query} -> [" INTERSECT (", all(query), ")"]
      {:intersect_all, query} -> [" INTERSECT ALL (", all(query), ")"]
    end)
  end

  def lock(query, _sources) do
    error!(query, "SQLite3 does not support locks")
  end

  defp boolean(_name, [], _sources, _query), do: []

  defp boolean(name, [%{expr: expr, op: op} | query_exprs], sources, query) do
    [
      name,
      Enum.reduce(query_exprs, {op, paren_expr(expr, sources, query)}, fn
        %BooleanExpr{expr: expr, op: op}, {op, acc} ->
          {op, [acc, operator_to_boolean(op) | paren_expr(expr, sources, query)]}

        %BooleanExpr{expr: expr, op: op}, {_, acc} ->
          {op,
           [?(, acc, ?), operator_to_boolean(op) | paren_expr(expr, sources, query)]}
      end)
      |> elem(1)
    ]
  end

  defp operator_to_boolean(:and), do: " AND "
  defp operator_to_boolean(:or), do: " OR "

  defp parens_for_select([first_expr | _] = expr) do
    if is_binary(first_expr) and String.match?(first_expr, ~r/^\s*select/i) do
      [?(, expr, ?)]
    else
      expr
    end
  end

  defp paren_expr(expr, sources, query) do
    [?(, expr(expr, sources, query), ?)]
  end

  ##
  ## Expression generation
  ##

  def expr({:^, [], [_ix]}, _sources, _query) do
    '?'
  end

  def expr(
        {{:., _, [{:parent_as, _, [{:&, _, [idx]}]}, field]}, _, []},
        _sources,
        query
      )
      when is_atom(field) do
    {_, name, _} = elem(query.aliases[@parent_as], idx)
    [name, ?. | quote_name(field)]
  end

  def expr({{:., _, [{:&, _, [idx]}, field]}, _, []}, sources, _query)
      when is_atom(field) do
    {_, name, _} = elem(sources, idx)
    [name, ?. | quote_name(field)]
  end

  def expr({:&, _, [idx]}, sources, _query) do
    {_, source, _} = elem(sources, idx)
    source
  end

  def expr({:in, _, [_left, []]}, _sources, _query) do
    "false"
  end

  def expr({:in, _, [left, right]}, sources, query) when is_list(right) do
    args = intersperse_map(right, ?,, &expr(&1, sources, query))
    [expr(left, sources, query), " IN (", args, ?)]
  end

  def expr({:in, _, [_, {:^, _, [_, 0]}]}, _sources, _query) do
    "false"
  end

  def expr({:in, _, [left, {:^, _, [_, length]}]}, sources, query) do
    args = Enum.intersperse(List.duplicate(??, length), ?,)
    [expr(left, sources, query), " IN (", args, ?)]
  end

  def expr({:in, _, [left, %Ecto.SubQuery{} = subquery]}, sources, query) do
    [expr(left, sources, query), " IN ", expr(subquery, sources, query)]
  end

  def expr({:in, _, [left, right]}, sources, query) do
    [expr(left, sources, query), " = ANY(", expr(right, sources, query), ?)]
  end

  def expr({:is_nil, _, [arg]}, sources, query) do
    [expr(arg, sources, query) | " IS NULL"]
  end

  def expr({:not, _, [expr]}, sources, query) do
    ["NOT (", expr(expr, sources, query), ?)]
  end

  def expr({:filter, _, _}, _sources, query) do
    error!(query, "SQLite3 adapter does not support aggregate filters")
  end

  def expr(%Ecto.SubQuery{query: query}, sources, _query) do
    query = put_in(query.aliases[@parent_as], sources)
    [?(, all(query, subquery_as_prefix(sources)), ?)]
  end

  def expr({:fragment, _, [kw]}, _sources, query)
      when is_list(kw) or tuple_size(kw) == 3 do
    error!(query, "SQLite3 adapter does not support keyword or interpolated fragments")
  end

  def expr({:fragment, _, parts}, sources, query) do
    parts
    |> Enum.map(fn
      {:raw, part} -> part
      {:expr, expr} -> expr(expr, sources, query)
    end)
    |> parens_for_select
  end

  def expr({:datetime_add, _, [datetime, count, interval]}, sources, query) do
    [
      "CAST (",
      "strftime('%Y-%m-%d %H:%M:%f000'",
      ",",
      expr(datetime, sources, query),
      ",",
      interval(count, interval, sources),
      ") AS TEXT_DATETIME)"
    ]
  end

  def expr({:date_add, _, [date, count, interval]}, sources, query) do
    [
      "CAST (",
      "strftime('%Y-%m-%d'",
      ",",
      expr(date, sources, query),
      ",",
      interval(count, interval, sources),
      ") AS TEXT_DATE)"
    ]
  end

  def expr({:ilike, _, [_, _]}, _sources, query) do
    raise Ecto.QueryError, query: query, message: "ilike is not supported by SQLite3"
  end

  def expr({:over, _, [agg, name]}, sources, query) when is_atom(name) do
    [expr(agg, sources, query), " OVER " | quote_name(name)]
  end

  def expr({:over, _, [agg, kw]}, sources, query) do
    [expr(agg, sources, query), " OVER " | window_exprs(kw, sources, query)]
  end

  def expr({:{}, _, elems}, sources, query) do
    [?(, intersperse_map(elems, ?,, &expr(&1, sources, query)), ?)]
  end

  def expr({:count, _, []}, _sources, _query), do: "count(*)"

  #
  # TODO: Sqlite has some json operation support
  #
  def expr({:json_extract_path, _, [_expr, _path]}, _sources, query) do
    raise Ecto.QueryError,
      query: query,
      message: "json_extract_path is not currently supported"
  end

  # def expr({:json_extract_path, _, [expr, path]}, sources, query) do
  #   path =
  #     Enum.map(path, fn
  #       binary when is_binary(binary) ->
  #         [?., ?", escape_json_key(binary), ?"]
  #
  #       integer when is_integer(integer) ->
  #         "[#{integer}]"
  #     end)
  #
  #   ["json_extract(", expr(expr, sources, query), ", '$", path, "')"]
  # end

  def expr({fun, _, args}, sources, query) when is_atom(fun) and is_list(args) do
    {modifier, args} =
      case args do
        [rest, :distinct] -> {"DISTINCT ", [rest]}
        _ -> {[], args}
      end

    case handle_call(fun, length(args)) do
      {:binary_op, op} ->
        [left, right] = args
        [op_to_binary(left, sources, query), op | op_to_binary(right, sources, query)]

      {:fun, fun} ->
        [fun, ?(, modifier, intersperse_map(args, ", ", &expr(&1, sources, query)), ?)]
    end
  end

  def expr(list, _sources, query) when is_list(list) do
    error!(query, "Array type is not supported by SQLite3")
  end

  def expr(%Decimal{} = decimal, _sources, _query) do
    Decimal.to_string(decimal, :normal)
  end

  def expr(%Ecto.Query.Tagged{value: binary, type: :binary}, _sources, _query)
      when is_binary(binary) do
    hex = Base.encode16(binary, case: :lower)
    [?x, ?', hex, ?']
  end

  def expr(%Ecto.Query.Tagged{value: other, type: type}, sources, query)
      when type in [:decimal, :float] do
    [expr(other, sources, query), " + 0"]
  end

  def expr(%Ecto.Query.Tagged{value: other, type: type}, sources, query) do
    ["CAST(", expr(other, sources, query), " AS ", ecto_cast_to_db(type, query), ?)]
  end

  def expr(nil, _sources, _query), do: "NULL"
  def expr(true, _sources, _query), do: "TRUE"
  def expr(false, _sources, _query), do: "FALSE"

  def expr(literal, _sources, _query) when is_binary(literal) do
    [?', escape_string(literal), ?']
  end

  def expr(literal, _sources, _query) when is_integer(literal) do
    Integer.to_string(literal)
  end

  def expr(literal, _sources, _query) when is_float(literal) do
    # Unsure if SQLite3 supports float casting
    ["(0 + ", Float.to_string(literal), ?)]
  end

  def interval(_, "microsecond", _sources) do
    raise ArgumentError,
          "SQLite does not support microsecond precision in datetime intervals"
  end

  def interval(count, "millisecond", sources) do
    "(#{expr(count, sources, nil)} / 1000.0) || ' seconds'"
  end

  def interval(count, "week", sources) do
    "(#{expr(count, sources, nil)} * 7) || ' days'"
  end

  def interval(count, interval, sources) do
    "#{expr(count, sources, nil)} || ' #{interval}'"
  end

  defp op_to_binary({op, _, [_, _]} = expr, sources, query) when op in @binary_ops,
    do: paren_expr(expr, sources, query)

  defp op_to_binary({:is_nil, _, [_]} = expr, sources, query),
    do: paren_expr(expr, sources, query)

  defp op_to_binary(expr, sources, query),
    do: expr(expr, sources, query)

  def create_names(query), do: create_names(query, [])

  def create_names(%{sources: sources}, as_prefix) do
    create_names(sources, 0, tuple_size(sources), as_prefix) |> List.to_tuple()
  end

  def create_names(sources, pos, limit, as_prefix) when pos < limit do
    [
      create_name(sources, pos, as_prefix)
      | create_names(sources, pos + 1, limit, as_prefix)
    ]
  end

  def create_names(_sources, pos, pos, as_prefix) do
    [as_prefix]
  end

  defp subquery_as_prefix(sources) do
    [?s | :erlang.element(tuple_size(sources), sources)]
  end

  def create_name(sources, pos, as_prefix) do
    case elem(sources, pos) do
      {:fragment, _, _} ->
        {nil, as_prefix ++ [?f | Integer.to_string(pos)], nil}

      {table, schema, prefix} ->
        name = as_prefix ++ [create_alias(table) | Integer.to_string(pos)]
        {quote_table(prefix, table), name, schema}

      %Ecto.SubQuery{} ->
        {nil, as_prefix ++ [?s | Integer.to_string(pos)], nil}
    end
  end

  def create_alias(<<first, _rest::binary>>)
      when first in ?a..?z
      when first in ?A..?Z do
    first
  end

  def create_alias(_) do
    ?t
  end

  defp column_definitions(table, columns) do
    intersperse_map(columns, ", ", &column_definition(table, &1))
  end

  defp column_definition(table, {:add, name, %Reference{} = ref, opts}) do
    [quote_name(name), ?\s, reference_column_type(ref.type, opts),
      column_options(table, ref.type, opts), reference_expr(ref, table, name)]
  end

  defp column_definition(table, {:add, name, type, opts}) do
    [quote_name(name), ?\s, column_type(type, opts), column_options(table, type, opts)]
  end

  defp column_change(table, {:add, name, %Reference{} = ref, opts}) do
    ["ADD COLUMN ", quote_name(name), ?\s, reference_column_type(ref.type, opts),
      column_options(table, ref.type, opts), reference_expr(ref, table, name)]
  end

  # If we are adding a DATETIME column with the NOT NULL constraint, SQLite
  # will force us to give it a DEFAULT value. The only default value
  # that makes sense is CURRENT_TIMESTAMP, but when adding a column to a
  # table, defaults must be constant values.
  #
  # Therefore the best option is just to remove the NOT NULL constraint when
  # we add new datetime columns.
  defp column_change(table, {:add, name, type, opts})
    when type in [:utc_datetime, :naive_datetime]
  do
    opts = Keyword.delete(opts, :null)
    [
      "ADD COLUMN ",
      quote_name(name),
      ?\s,
      column_type(type, opts),
      column_options(table, type, opts)
    ]
  end

  defp column_change(table, {:add, name, type, opts}) do
    [
      "ADD COLUMN ",
      quote_name(name),
      ?\s,
      column_type(type, opts),
      column_options(table, type, opts)
    ]
  end

  defp column_change(_table, {:modify, _name, _type, _opts}) do
    raise ArgumentError, "ALTER COLUMN not supported by SQLite"
  end

  defp column_change(_table, {:remove, _name, _type, _opts}) do
    raise ArgumentError, "ALTER COLUMN not supported by SQLite"
  end

  defp column_change(_table, {:remove, :summary}) do
    raise ArgumentError, "DROP COLUMN not supported by SQLite"
  end

  defp column_change(_table, _) do
    raise ArgumentError, "Not supported by SQLite"
  end

  defp column_options(table, type, opts) do
    default = Keyword.fetch(opts, :default)
    null    = Keyword.get(opts, :null)
    pk      = (table.primary_key != :composite) and Keyword.get(opts, :primary_key, false)

    column_options(default, type, null, pk)
  end

  defp column_options(_default, :serial, _, true) do
    " PRIMARY KEY AUTOINCREMENT"
  end
  defp column_options(default, type, null, pk) do
    [default_expr(default, type), null_expr(null), pk_expr(pk)]
  end

  defp null_expr(false), do: " NOT NULL"
  defp null_expr(true), do: " NULL"
  defp null_expr(_), do: []

  defp default_expr({:ok, nil}, _type) do
    " DEFAULT NULL"
  end

  defp default_expr({:ok, literal}, _type) when is_binary(literal) do
    [
      " DEFAULT '",
      escape_string(literal),
      ?'
    ]
  end

  defp default_expr({:ok, literal}, _type) when is_number(literal) or is_boolean(literal) do
    [
      " DEFAULT ",
      to_string(literal)
    ]
  end

  defp default_expr({:ok, {:fragment, expr}}, _type) do
    [
      " DEFAULT ",
      expr
    ]
  end

  defp default_expr({:ok, value}, _type) when is_map(value) do
    library = Application.get_env(:myxql, :json_library, Jason)
    expr = IO.iodata_to_binary(library.encode_to_iodata!(value))
    [
      " DEFAULT ",
      ?(,
        ?',
        escape_string(expr),
        ?',
        ?)
    ]
  end

  defp default_expr(:error, _type), do: []

  defp index_expr(literal) when is_binary(literal), do: literal
  defp index_expr(literal), do: quote_name(literal)

  defp pk_expr(true), do: " PRIMARY KEY"
  defp pk_expr(_), do: []

  defp options_expr(nil), do: []
  defp options_expr(keyword) when is_list(keyword) do
    raise ArgumentError, "SQLite3 adapter does not support keyword lists in :options"
  end

  defp options_expr(options), do: [?\s, to_string(options)]

  # Simple column types. Note that we ignore options like :size, :precision,
  # etc. because columns do not have types, and SQLite will not coerce any
  # stored value. Thus, "strings" are all text and "numerics" have arbitrary
  # precision regardless of the declared column type. Decimals are the
  # only exception.
  defp column_type(:serial, _opts), do: "INTEGER"
  defp column_type(:bigserial, _opts), do: "INTEGER"
  defp column_type(:string, _opts), do: "TEXT"
  defp column_type(:map, _opts), do: "TEXT"
  defp column_type({:map, _}, _opts), do: "JSON"
  defp column_type({:array, _}, _opts), do: "JSON"

  defp column_type(:decimal, opts) do
    # We only store precision and scale for DECIMAL.
    precision = Keyword.get(opts, :precision)
    scale = Keyword.get(opts, :scale, 0)

    decimal_column_type(precision, scale)
  end

  defp column_type(type, _opts) do
    type
    |> Atom.to_string()
    |> String.upcase()
  end

  defp decimal_column_type(precision, scale) when is_integer(precision) do
    "DECIMAL(#{precision},#{scale})"
  end

  defp decimal_column_type(_precision, _scale), do: "DECIMAL"

  defp reference_expr(type, ref, table, name) do
    {current_columns, reference_columns} = Enum.unzip([{name, ref.column} | ref.with])

    if ref.match do
      raise ArgumentError, ":match is not supported in references for tds"
    end

    [
      "CONSTRAINT ",
      reference_name(ref, table, name),
      " ",
      type,
      " (",
      quote_names(current_columns),
      ?),
      " REFERENCES ",
      quote_table(ref.prefix || table.prefix, ref.table),
      ?(,
      quote_names(reference_columns),
      ?),
      reference_on_delete(ref.on_delete),
      reference_on_update(ref.on_update)
    ]
  end

  defp reference_expr(%Reference{} = ref, table, name) do
    [", " | reference_expr("FOREIGN KEY", ref, table, name)]
  end

  defp reference_name(%Reference{name: nil}, table, column) do
    quote_name("#{table.name}_#{column}_fkey")
  end

  defp reference_name(%Reference{name: name}, _table, _column) do
    quote_name(name)
  end

  defp reference_column_type(:serial, _opts), do: "INTEGER"
  defp reference_column_type(:bigserial, _opts), do: "INTEGER"
  defp reference_column_type(type, opts), do: column_type(type, opts)

  defp reference_on_delete(:nilify_all), do: " ON DELETE SET NULL"
  defp reference_on_delete(:delete_all), do: " ON DELETE CASCADE"
  defp reference_on_delete(:restrict), do: " ON DELETE RESTRICT"
  defp reference_on_delete(_), do: []

  defp reference_on_update(:nilify_all), do: " ON UPDATE SET NULL"
  defp reference_on_update(:update_all), do: " ON UPDATE CASCADE"
  defp reference_on_update(:restrict), do: " ON UPDATE RESTRICT"
  defp reference_on_update(_), do: []

  ##
  ## Helpers
  ##

  defp composite_pk_definition(%Table{} = table, columns) do
    pks = Enum.reduce(columns, [], fn({_, name, _, opts}, pk_acc) ->
      case Keyword.get(opts, :primary_key, false) do
        true -> [name | pk_acc]
        false -> pk_acc
      end
    end)

    if length(pks) > 1 do
      composite_pk_expr = pks |> Enum.reverse() |> Enum.map_join(", ", &quote_name/1)
      {%{table | primary_key: :composite}, ", PRIMARY KEY (" <> composite_pk_expr <> ")"}
    else
      {table, ""}
    end
  end

  defp get_source(query, sources, ix, source) do
    {expr, name, _schema} = elem(sources, ix)
    {expr || expr(source, sources, query), name}
  end

  defp quote_names(names), do: intersperse_map(names, ?,, &quote_name/1)

  def quote_name(name), do: quote_entity(name)

  def quote_table(table), do: quote_entity(table)

  defp quote_table(nil, name), do: quote_entity(name)
  defp quote_table(prefix, name), do: [quote_entity(prefix), ?., quote_entity(name)]

  defp quote_entity(val) when is_atom(val) do
    quote_entity(Atom.to_string(val))
  end
  defp quote_entity(val), do: [val]

  defp intersperse_map(list, separator, mapper, acc \\ [])
  defp intersperse_map([], _separator, _mapper, acc) do
    acc
  end

  defp intersperse_map([elem], _separator, mapper, acc) do
    [acc | mapper.(elem)]
  end

  defp intersperse_map([elem | rest], separator, mapper, acc) do
    intersperse_map(rest, separator, mapper, [acc, mapper.(elem), separator])
  end

  defp if_do(condition, value) do
    if condition, do: value, else: []
  end

  defp escape_string(value) when is_binary(value) do
    value
    |> :binary.replace("'", "''", [:global])
    |> :binary.replace("\\", "\\\\", [:global])
  end

  # defp escape_json_key(value) when is_binary(value) do
  #   value
  #   |> escape_string()
  #   |> :binary.replace("\"", "\\\\\"", [:global])
  # end

  defp ecto_cast_to_db(:id, _query), do: "INTEGER"
  defp ecto_cast_to_db(:integer, _query), do: "INTEGER"
  defp ecto_cast_to_db(:string, _query), do: "TEXT"
  defp ecto_cast_to_db(type, query), do: ecto_to_db(type, query)

  defp ecto_to_db({:array, _}, query),
    do: error!(query, "Array type is not supported by SQLite3")

  defp ecto_to_db(:id, _query), do: "INTEGER"
  defp ecto_to_db(:serial, _query), do: "INTEGER"
  defp ecto_to_db(:bigserial, _query), do: "INTEGER"
  # TODO: We should make this configurable
  defp ecto_to_db(:binary_id, _query), do: "TEXT"
  defp ecto_to_db(:string, _query), do: "TEXT"
  defp ecto_to_db(:float, _query), do: "NUMERIC"
  defp ecto_to_db(:binary, _query), do: "BLOB"
  # TODO: We should make this configurable
  # SQLite3 does not support uuid
  defp ecto_to_db(:uuid, _query), do: "TEXT"
  defp ecto_to_db(:map, _query), do: "TEXT"
  defp ecto_to_db({:map, _}, _query), do: "TEXT"
  defp ecto_to_db(:utc_datetime, _query), do: "TEXT_DATETIME"
  defp ecto_to_db(:utc_datetime_usec, _query), do: "TEXT_DATETIME"
  defp ecto_to_db(:naive_datetime, _query), do: "TEXT_DATETIME"
  defp ecto_to_db(:naive_datetime_usec, _query), do: "TEXT_DATETIME"
  defp ecto_to_db(atom, _query) when is_atom(atom), do: Atom.to_string(atom)
  defp ecto_to_db(str, _query) when is_binary(str), do: str

  defp ecto_to_db(type, _query) do
    raise ArgumentError,
          "unsupported type `#{inspect(type)}`. The type can either be an atom, a string " <>
            "or a tuple of the form `{:map, t}` where `t` itself follows the same conditions."
  end

  defp error!(nil, message) do
    raise ArgumentError, message
  end

  defp error!(query, message) do
    raise Ecto.QueryError, query: query, message: message
  end
end
