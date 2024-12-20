defmodule Ecto.Adapters.SQLite3.Connection do
  @moduledoc false

  @behaviour Ecto.Adapters.SQL.Connection

  alias Ecto.Adapters.SQL
  alias Ecto.Migration.Constraint
  alias Ecto.Migration.Index
  alias Ecto.Migration.Reference
  alias Ecto.Migration.Table
  alias Ecto.Query.BooleanExpr
  alias Ecto.Query.ByExpr
  alias Ecto.Query.JoinExpr
  alias Ecto.Query.QueryExpr
  alias Ecto.Query.WithExpr

  import Ecto.Adapters.SQLite3.DataType

  @parent_as __MODULE__

  defp default_opts(opts) do
    opts
    |> Keyword.put_new(:journal_mode, :wal)
    |> Keyword.put_new(:cache_size, -64_000)
    |> Keyword.put_new(:temp_store, :memory)
    |> Keyword.put_new(:pool_size, 5)
  end

  def start_link(opts) do
    opts = default_opts(opts)
    DBConnection.start_link(Exqlite.Connection, opts)
  end

  @impl true
  def child_spec(options) do
    {:ok, _} = Application.ensure_all_started(:db_connection)
    options = default_opts(options)
    DBConnection.child_spec(Exqlite.Connection, options)
  end

  @impl true
  def prepare_execute(conn, name, sql, params, options) do
    query = Exqlite.Query.build(name: name, statement: sql)

    case DBConnection.prepare_execute(conn, query, params, options) do
      {:ok, _, _} = ok -> ok
      {:error, %Exqlite.Error{}} = error -> error
      {:error, err} -> raise err
    end
  end

  @impl true
  def execute(conn, %Exqlite.Query{ref: ref} = cached, params, options)
      when ref != nil do
    DBConnection.execute(conn, cached, params, options)
  end

  def execute(
        conn,
        %Exqlite.Query{statement: statement, ref: nil},
        params,
        options
      ) do
    execute(conn, statement, params, options)
  end

  def execute(conn, sql, params, options) when is_binary(sql) or is_list(sql) do
    query = Exqlite.Query.build(name: "", statement: IO.iodata_to_binary(sql))

    case DBConnection.prepare_execute(conn, query, params, options) do
      {:ok, %Exqlite.Query{}, result} -> {:ok, result}
      {:error, %Exqlite.Error{}} = error -> error
      {:error, err} -> raise err
    end
  end

  def execute(conn, query, params, options) do
    case DBConnection.execute(conn, query, params, options) do
      {:ok, _} = ok -> ok
      {:error, %ArgumentError{} = err} -> {:reset, err}
      {:error, %Exqlite.Error{}} = error -> error
      {:error, err} -> raise err
    end
  end

  @impl true
  def query(conn, sql, params, options) do
    query = Exqlite.Query.build(statement: IO.iodata_to_binary(sql))

    case DBConnection.execute(conn, query, params, options) do
      {:ok, _, result} -> {:ok, result}
      other -> other
    end
  end

  @impl true
  def query_many(_conn, _sql, _params, _opts) do
    raise RuntimeError, "query_many is not supported in the SQLite3 adapter"
  end

  @impl true
  def stream(conn, sql, params, options) do
    query = Exqlite.Query.build(statement: sql)
    DBConnection.stream(conn, query, params, options)
  end

  # we want to return the name of the underlying index that caused
  # the constraint error, but in SQLite as far as I can tell there
  # is no way to do this, so we name the index according to ecto
  # convention, even if technically it _could_ have a different name
  defp constraint_name_hack(constraint) do
    if String.contains?(constraint, ", ") do
      # "a.b, a.c" -> a_b_c_index
      constraint
      |> String.split(", ")
      |> Enum.with_index()
      |> Enum.map(fn
        {table_col, 0} ->
          String.replace(table_col, ".", "_")

        {table_col, _} ->
          table_col
          |> String.split(".")
          |> List.last()
      end)
      |> Enum.concat(["index"])
      |> Enum.join("_")
    else
      constraint
      |> String.split(".")
      |> Enum.concat(["index"])
      |> Enum.join("_")
    end
  end

  @impl true
  def to_constraints(
        %Exqlite.Error{message: "UNIQUE constraint failed: index " <> constraint},
        _opts
      ) do
    [unique: String.trim(constraint, ~s('))]
  end

  def to_constraints(
        %Exqlite.Error{message: "UNIQUE constraint failed: " <> constraint},
        _opts
      ) do
    [unique: constraint_name_hack(constraint)]
  end

  def to_constraints(%Exqlite.Error{message: "FOREIGN KEY constraint failed"}, _opts) do
    # unfortunately we have no other date from SQLite
    [foreign_key: nil]
  end

  def to_constraints(
        %Exqlite.Error{message: "CHECK constraint failed: " <> name},
        _opts
      ) do
    [check: name]
  end

  def to_constraints(_, _), do: []

  ##
  ## Queries
  ##

  @impl true
  def all(%Ecto.Query{lock: lock}) when lock != nil do
    raise ArgumentError, "locks are not supported by SQLite3"
  end

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
    combinations = combinations(query, as_prefix)
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
  def update_all(query, prefix \\ nil) do
    %{from: %{source: source}} = query

    sources = create_names(query, [])
    cte = cte(query, sources)
    {from, name} = get_source(query, sources, 0, source)

    fields =
      if prefix do
        update_fields(:on_conflict, query, sources)
      else
        update_fields(:update, query, sources)
      end

    # TODO: Add support for `update or rollback foo`

    {join, wheres} = using_join(query, :update_all, "FROM", sources)
    prefix = prefix || ["UPDATE ", from, " AS ", name, " SET "]
    where = where(%{query | wheres: wheres ++ query.wheres}, sources)

    [
      cte,
      prefix,
      fields,
      join,
      where,
      returning(query, sources)
    ]
  end

  @impl true
  def delete_all(%Ecto.Query{joins: [_ | _]}) do
    # TODO: It is supported but not in the traditional sense
    raise ArgumentError, "JOINS are not supported on DELETE statements by SQLite"
  end

  def delete_all(query) do
    sources = create_names(query, [])
    cte = cte(query, sources)

    from = from(query, sources)
    where = where(query, sources)

    [
      cte,
      "DELETE",
      from,
      where,
      returning(query, sources)
    ]
  end

  @impl true
  def insert(prefix, table, [], [[]], on_conflict, returning, []) do
    [
      "INSERT INTO ",
      quote_table(prefix, table),
      insert_as(on_conflict),
      " DEFAULT VALUES",
      returning(returning)
    ]
  end

  def insert(prefix, table, header, rows, on_conflict, returning, placeholders) do
    counter_offset = length(placeholders) + 1

    values =
      if header == [] do
        [" VALUES " | Enum.map_intersperse(rows, ?,, fn _ -> "(DEFAULT)" end)]
      else
        [" (", quote_names(header), ") " | insert_all(rows, counter_offset)]
      end

    [
      "INSERT INTO ",
      quote_table(prefix, table),
      insert_as(on_conflict),
      values,
      on_conflict(on_conflict, header),
      returning(returning)
    ]
  end

  @impl true
  def update(prefix, table, fields, filters, returning) do
    fields = Enum.map_intersperse(fields, ", ", &[quote_name(&1), " = ?"])

    filters =
      Enum.map_intersperse(filters, " AND ", fn
        {field, nil} ->
          [quote_name(field), " IS NULL"]

        {field, _value} ->
          [quote_name(field), " = ?"]
      end)

    [
      "UPDATE ",
      quote_table(prefix, table),
      " SET ",
      fields,
      " WHERE ",
      filters,
      returning(returning)
    ]
  end

  @impl true
  def delete(prefix, table, filters, returning) do
    filters =
      Enum.map_intersperse(filters, " AND ", fn
        {field, nil} ->
          [quote_name(field), " IS NULL"]

        {field, _value} ->
          [quote_name(field), " = ?"]
      end)

    [
      "DELETE FROM ",
      quote_table(prefix, table),
      " WHERE ",
      filters,
      returning(returning)
    ]
  end

  @impl true
  def explain_query(conn, query, params, opts) do
    type = Keyword.get(opts, :type, :query_plan)

    case query(conn, build_explain_query(query, type), params, opts) do
      {:ok, %Exqlite.Result{} = result} ->
        case type do
          :query_plan -> {:ok, format_query_plan_explain(result)}
          :instructions -> {:ok, SQL.format_table(result)}
        end

      error ->
        error
    end
  end

  def build_explain_query(query, :query_plan) do
    IO.iodata_to_binary(["EXPLAIN QUERY PLAN ", query])
  end

  def build_explain_query(query, :instructions) do
    IO.iodata_to_binary(["EXPLAIN ", query])
  end

  # Mimics the ASCII format of the sqlite CLI
  defp format_query_plan_explain(%{rows: rows}) do
    {lines, _} =
      rows
      |> Enum.chunk_every(2, 1, [nil])
      |> Enum.map_reduce(0, fn [[id, parent, _, text], next], depth ->
        {branch, next_depth} =
          case {id, parent, next} do
            {id, _, [_, id, _, _]} -> {"|--", depth + 1}
            {_, p, [_, p, _, _]} -> {"|--", depth}
            _ -> {"`--", depth - 1}
          end

        formatted_line = String.duplicate("|  ", depth) <> branch <> text
        {formatted_line, next_depth}
      end)

    Enum.join(["QUERY PLAN" | lines], "\n")
  end

  ##
  ## DDL
  ##

  @impl true
  def execute_ddl({_command, %Table{options: options}, _}) when is_list(options) do
    raise ArgumentError, "SQLite3 adapter does not support keyword lists in :options"
  end

  def execute_ddl({:create, %Table{} = table, columns}) do
    {table, composite_pk_def} = composite_pk_definition(table, columns)
    composite_fk_defs = composite_fk_definitions(table, columns)

    [
      [
        "CREATE TABLE ",
        quote_table(table.prefix, table.name),
        ?\s,
        ?(,
        column_definitions(table, columns),
        composite_pk_def,
        composite_fk_defs,
        ?),
        options_expr(table.options)
      ]
    ]
  end

  def execute_ddl({:create_if_not_exists, %Table{} = table, columns}) do
    {table, composite_pk_def} = composite_pk_definition(table, columns)
    composite_fk_defs = composite_fk_definitions(table, columns)

    [
      [
        "CREATE TABLE IF NOT EXISTS ",
        quote_table(table.prefix, table.name),
        ?\s,
        ?(,
        column_definitions(table, columns),
        composite_pk_def,
        composite_fk_defs,
        ?),
        options_expr(table.options)
      ]
    ]
  end

  def execute_ddl({:drop, %Table{} = table}) do
    [
      [
        "DROP TABLE ",
        quote_table(table.prefix, table.name)
      ]
    ]
  end

  def execute_ddl({:drop, %Table{} = table, _mode}) do
    execute_ddl({:drop, table})
  end

  def execute_ddl({:drop_if_exists, %Table{} = table}) do
    [
      [
        "DROP TABLE IF EXISTS ",
        quote_table(table.prefix, table.name)
      ]
    ]
  end

  def execute_ddl({:drop_if_exists, %Table{} = table, _mode}) do
    execute_ddl({:drop_if_exists, table})
  end

  def execute_ddl({:alter, %Table{} = table, changes}) do
    Enum.map(changes, fn change ->
      [
        "ALTER TABLE ",
        quote_table(table.prefix, table.name),
        ?\s,
        column_change(table, change)
      ]
    end)
  end

  @impl true
  def execute_ddl({_, %Index{concurrently: true}}) do
    raise ArgumentError, "`concurrently` is not supported with SQLite3"
  end

  @impl true
  def execute_ddl({_, %Index{only: true}}) do
    raise ArgumentError, "`only` is not supported with SQLite3"
  end

  @impl true
  def execute_ddl({_, %Index{include: x}}) when length(x) != 0 do
    raise ArgumentError, "`include` is not supported with SQLite3"
  end

  @impl true
  def execute_ddl({_, %Index{using: x}}) when not is_nil(x) do
    raise ArgumentError, "`using` is not supported with SQLite3"
  end

  @impl true
  def execute_ddl({_, %Index{nulls_distinct: x}}) when not is_nil(x) do
    raise ArgumentError, "`nulls_distinct` is not supported with SQLite3"
  end

  @impl true
  def execute_ddl({:create, %Index{} = index}) do
    fields = Enum.map_intersperse(index.columns, ", ", &index_expr/1)

    [
      [
        "CREATE ",
        if_do(index.unique, "UNIQUE "),
        "INDEX ",
        quote_name(index.name),
        " ON ",
        quote_table(index.prefix, index.table),
        " (",
        fields,
        ?),
        if_do(index.where, [" WHERE ", to_string(index.where)])
      ]
    ]
  end

  @impl true
  def execute_ddl({:create_if_not_exists, %Index{} = index}) do
    fields = Enum.map_intersperse(index.columns, ", ", &index_expr/1)

    [
      [
        "CREATE ",
        if_do(index.unique, "UNIQUE "),
        "INDEX IF NOT EXISTS ",
        quote_name(index.name),
        " ON ",
        quote_table(index.prefix, index.table),
        " (",
        fields,
        ?),
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
  def execute_ddl({:drop, %Index{} = index, _mode}) do
    execute_ddl({:drop, index})
  end

  @impl true
  def execute_ddl({:drop_if_exists, %Index{concurrently: true}}) do
    raise ArgumentError, "`concurrently` is not supported with SQLite3"
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
  def execute_ddl({:drop_if_exists, %Index{} = index, _mode}) do
    execute_ddl({:drop_if_exists, index})
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
  def execute_ddl(string) when is_binary(string), do: [string]

  @impl true
  def execute_ddl(keyword) when is_list(keyword) do
    raise ArgumentError, "SQLite3 adapter does not support keyword lists in execute"
  end

  @impl true
  def execute_ddl({:create, %Index{} = index}) do
    fields = Enum.map_intersperse(index.columns, ", ", &index_expr/1)

    [
      [
        "CREATE ",
        if_do(index.unique, "UNIQUE "),
        "INDEX",
        ?\s,
        quote_name(index.name),
        " ON ",
        quote_table(index.prefix, index.table),
        " (",
        fields,
        ?),
        if_do(index.where, [" WHERE ", to_string(index.where)])
      ]
    ]
  end

  def execute_ddl({:create_if_not_exists, %Index{} = index}) do
    fields = Enum.map_intersperse(index.columns, ", ", &index_expr/1)

    [
      [
        "CREATE ",
        if_do(index.unique, "UNIQUE "),
        "INDEX IF NOT EXISTS",
        ?\s,
        quote_name(index.name),
        " ON ",
        quote_table(index.prefix, index.table),
        " (",
        fields,
        ?),
        if_do(index.where, [" WHERE ", to_string(index.where)])
      ]
    ]
  end

  def execute_ddl({:create, %Constraint{}}) do
    raise ArgumentError, "SQLite3 does not support ALTER TABLE ADD CONSTRAINT."
  end

  def execute_ddl({:drop, %Index{} = index}) do
    [
      [
        "DROP INDEX ",
        quote_table(index.prefix, index.name)
      ]
    ]
  end

  def execute_ddl({:drop, %Index{} = index, _mode}) do
    execute_ddl({:drop, index})
  end

  def execute_ddl({:drop_if_exists, %Index{} = index}) do
    [
      [
        "DROP INDEX IF EXISTS ",
        quote_table(index.prefix, index.name)
      ]
    ]
  end

  def execute_ddl({:drop_if_exists, %Index{} = index, _mode}) do
    execute_ddl({:drop_if_exists, index})
  end

  def execute_ddl({:drop, %Constraint{}, _mode}) do
    raise ArgumentError, "SQLite3 does not support ALTER TABLE DROP CONSTRAINT."
  end

  def execute_ddl({:drop_if_exists, %Constraint{}, _mode}) do
    raise ArgumentError, "SQLite3 does not support ALTER TABLE DROP CONSTRAINT."
  end

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

  def execute_ddl({:rename, %Index{} = index, new_index}) do
    [
      execute_ddl({:drop, index}),
      execute_ddl({:create, %Index{index | name: new_index}})
    ]
  end

  def execute_ddl(string) when is_binary(string), do: [string]

  def execute_ddl(keyword) when is_list(keyword) do
    raise ArgumentError, "SQLite3 adapter does not support keyword lists in execute"
  end

  @impl true
  def ddl_logs(_), do: []

  @impl true
  def table_exists_query(table) do
    {"SELECT name FROM sqlite_master WHERE type='table' AND name=? LIMIT 1", [table]}
  end

  ##
  ## Query generation
  ##

  defp on_conflict({:raise, _, []}, _header), do: []

  defp on_conflict({:nothing, _, targets}, _header) do
    [" ON CONFLICT ", conflict_target(targets) | "DO NOTHING"]
  end

  defp on_conflict({:replace_all, _, {:constraint, _}}, _header) do
    raise ArgumentError, "Upsert in SQLite3 does not support ON CONSTRAINT"
  end

  defp on_conflict({:replace_all, _, []}, _header) do
    raise ArgumentError, "Upsert in SQLite3 requires :conflict_target"
  end

  defp on_conflict({:replace_all, _, targets}, header) do
    [" ON CONFLICT ", conflict_target(targets), "DO " | replace(header)]
  end

  defp on_conflict({fields, _, targets}, _header) when is_list(fields) do
    [" ON CONFLICT ", conflict_target(targets), "DO " | replace(fields)]
  end

  defp on_conflict({query, _, targets}, _header) do
    [
      " ON CONFLICT ",
      conflict_target(targets),
      "DO " | update_all(query, "UPDATE SET ")
    ]
  end

  defp conflict_target([]), do: ""

  defp conflict_target({:unsafe_fragment, fragment}),
    do: [fragment, ?\s]

  defp conflict_target(targets) do
    [?(, Enum.map_intersperse(targets, ?,, &quote_name/1), ?), ?\s]
  end

  defp replace(fields) do
    [
      "UPDATE SET "
      | Enum.map_intersperse(fields, ?,, fn field ->
          quoted = quote_name(field)
          [quoted, " = ", "EXCLUDED." | quoted]
        end)
    ]
  end

  def insert_all(rows), do: insert_all(rows, 1)

  def insert_all(%Ecto.Query{} = query, _counter) do
    [all(query)]
  end

  def insert_all(rows, counter) do
    [
      "VALUES ",
      intersperse_reduce(
        rows,
        ?,,
        counter,
        fn row, counter ->
          {row, counter} = insert_each(row, counter)
          {[?(, row, ?)], counter}
        end
      )
      |> elem(0)
    ]
  end

  def insert_each(values, counter) do
    intersperse_reduce(values, ?,, counter, fn
      nil, _counter ->
        raise ArgumentError,
              "Cell-wise default values are not supported on INSERT statements by SQLite3"

      {%Ecto.Query{} = query, params_counter}, counter ->
        {[?(, all(query), ?)], counter + params_counter}

      {:placeholder, placeholder_index}, counter ->
        {[?? | placeholder_index], counter}

      _, counter ->
        # Cell wise value support ex: (?1, ?2, ?3)
        {[?? | Integer.to_string(counter)], counter + 1}
    end)
  end

  defp insert_as({%{sources: sources}, _, _}) do
    {_expr, name, _schema} = create_name(sources, 0, [])
    [" AS " | name]
  end

  defp insert_as({_, _, _}) do
    []
  end

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

  defp distinct(nil, _sources, _query), do: []
  defp distinct(%ByExpr{expr: true}, _sources, _query), do: "DISTINCT "
  defp distinct(%ByExpr{expr: false}, _sources, _query), do: []

  defp distinct(%ByExpr{expr: exprs}, _sources, query) when is_list(exprs) do
    raise Ecto.QueryError,
      query: query,
      message: "DISTINCT with multiple columns is not supported by SQLite3"
  end

  defp select(%{select: %{fields: fields}, distinct: distinct} = query, sources) do
    [
      "SELECT ",
      distinct(distinct, sources, query) | select_fields(fields, sources, query)
    ]
  end

  defp select_fields([], _sources, _query), do: "1"

  defp select_fields(fields, sources, query) do
    Enum.map_intersperse(fields, ", ", fn
      {:&, _, [idx]} ->
        case elem(sources, idx) do
          {source, _, nil} ->
            raise Ecto.QueryError,
              query: query,
              message: """
              SQLite3 does not support selecting all fields from #{source} \
              without a schema. Please specify a schema or specify exactly \
              which fields you want to select\
              """

          {_, source, _} ->
            source
        end

      {key, value} ->
        [expr(value, sources, query), " AS ", quote_name(key)]

      value ->
        expr(value, sources, query)
    end)
  end

  def from(%{from: %{source: source, hints: hints}} = query, sources) do
    {from, name} = get_source(query, sources, 0, source)

    [
      " FROM ",
      from,
      " AS ",
      name
      | Enum.map(hints, &[?\s | &1])
    ]
  end

  def cte(
        %{with_ctes: %WithExpr{recursive: recursive, queries: [_ | _] = queries}} =
          query,
        sources
      ) do
    recursive_opt = if recursive, do: "RECURSIVE ", else: ""
    ctes = Enum.map_intersperse(queries, ", ", &cte_expr(&1, sources, query))

    [
      "WITH ",
      recursive_opt,
      ctes,
      " "
    ]
  end

  def cte(%{with_ctes: _}, _), do: []

  defp cte_expr({name, _opts, cte}, sources, query) do
    cte_expr({name, cte}, sources, query)
  end

  defp cte_expr({name, cte}, sources, query) do
    [
      quote_name(name),
      " AS ",
      cte_query(cte, sources, query)
    ]
  end

  defp cte_query(%Ecto.Query{} = query, sources, parent_query) do
    query = put_in(query.aliases[@parent_as], {parent_query, sources})
    ["(", all(query, subquery_as_prefix(sources)), ")"]
  end

  defp cte_query(%QueryExpr{expr: expr}, sources, query) do
    expr(expr, sources, query)
  end

  defp update_fields(type, %{updates: updates} = query, sources) do
    fields =
      for(
        %{expr: expression} <- updates,
        {op, kw} <- expression,
        {key, value} <- kw,
        do: update_op(op, update_key(type, key, query, sources), value, sources, query)
      )

    Enum.intersperse(fields, ", ")
  end

  defp update_key(_kind, key, _query, _sources) do
    quote_name(key)
  end

  defp update_op(:set, quoted_key, value, sources, query) do
    [
      quoted_key,
      " = " | expr(value, sources, query)
    ]
  end

  defp update_op(:inc, quoted_key, value, sources, query) do
    [
      quoted_key,
      " = ",
      quoted_key,
      " + " | expr(value, sources, query)
    ]
  end

  defp update_op(:push, _quoted_key, _value, _sources, query) do
    raise Ecto.QueryError,
      query: query,
      message: "Arrays are not supported for SQLite3"
  end

  defp update_op(:pull, _quoted_key, _value, _sources, query) do
    raise Ecto.QueryError,
      query: query,
      message: "Arrays are not supported for SQLite3"
  end

  defp update_op(command, _quoted_key, _value, _sources, query) do
    raise Ecto.QueryError,
      query: query,
      message: "Unknown update operation #{inspect(command)} for SQLite3"
  end

  defp using_join(%{joins: []}, _kind, _prefix, _sources), do: {[], []}

  defp using_join(%{joins: joins} = query, _kind, prefix, sources) do
    froms =
      Enum.map_intersperse(joins, ", ", fn
        %JoinExpr{qual: _qual, ix: ix, source: source} = join ->
          assert_valid_join(join, query)
          {join, name} = get_source(query, sources, ix, source)
          [join, " AS " | name]
      end)

    wheres =
      for %JoinExpr{on: %QueryExpr{expr: value} = query_expr} <- joins,
          value != true,
          do: query_expr |> Map.put(:__struct__, BooleanExpr) |> Map.put(:op, :and)

    {[?\s, prefix, ?\s | froms], wheres}
  end

  def join(%{joins: []}, _sources), do: []

  def join(%{joins: joins} = query, sources) do
    Enum.map(joins, fn
      %JoinExpr{
        on: %QueryExpr{expr: expression},
        qual: qual,
        ix: ix,
        source: source
      } = join ->
        assert_valid_join(join, query)

        {join, name} = get_source(query, sources, ix, source)

        [
          join_qual(qual, query),
          join,
          " AS ",
          name,
          join_on(qual, expression, sources, query)
        ]
    end)
  end

  defp assert_valid_join(%JoinExpr{hints: hints}, query) when hints != [] do
    raise Ecto.QueryError,
      query: query,
      message: "join hints are not supported by SQLite3"
  end

  defp assert_valid_join(%JoinExpr{source: {:values, _, _}}, query) do
    raise Ecto.QueryError,
      query: query,
      message: "SQLite3 adapter does not support values lists"
  end

  defp assert_valid_join(_join_expr, _query), do: :ok

  defp join_on(:cross, true, _sources, _query), do: []

  defp join_on(_qual, expression, sources, query),
    do: [" ON " | expr(expression, sources, query)]

  defp join_qual(:inner, _), do: " INNER JOIN "
  defp join_qual(:left, _), do: " LEFT OUTER JOIN "
  defp join_qual(:right, _), do: " RIGHT OUTER JOIN "
  defp join_qual(:full, _), do: " FULL OUTER JOIN "
  defp join_qual(:cross, _), do: " CROSS JOIN "

  defp join_qual(mode, query) do
    raise Ecto.QueryError,
      query: query,
      message: "join `#{inspect(mode)}` not supported by SQLite3"
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
      | Enum.map_intersperse(group_bys, ", ", fn %ByExpr{expr: expression} ->
          Enum.map_intersperse(expression, ", ", &top_level_expr(&1, sources, query))
        end)
    ]
  end

  def window(%{windows: []}, _sources), do: []

  def window(%{windows: windows} = query, sources) do
    [
      " WINDOW "
      | Enum.map_intersperse(windows, ", ", fn {name, %{expr: kw}} ->
          [quote_name(name), " AS " | window_exprs(kw, sources, query)]
        end)
    ]
  end

  defp window_exprs(kw, sources, query) do
    [?(, Enum.map_intersperse(kw, ?\s, &window_expr(&1, sources, query)), ?)]
  end

  defp window_expr({:partition_by, fields}, sources, query) do
    ["PARTITION BY " | Enum.map_intersperse(fields, ", ", &expr(&1, sources, query))]
  end

  defp window_expr({:order_by, fields}, sources, query) do
    [
      "ORDER BY "
      | Enum.map_intersperse(fields, ", ", &order_by_expr(&1, sources, query))
    ]
  end

  defp window_expr({:frame, {:fragment, _, _} = fragment}, sources, query) do
    expr(fragment, sources, query)
  end

  def order_by(%{order_bys: []}, _sources), do: []

  def order_by(%{order_bys: order_bys} = query, sources) do
    order_bys = Enum.flat_map(order_bys, & &1.expr)

    [
      " ORDER BY "
      | Enum.map_intersperse(order_bys, ", ", &order_by_expr(&1, sources, query))
    ]
  end

  defp order_by_expr({dir, expression}, sources, query) do
    str = top_level_expr(expression, sources, query)

    case dir do
      :asc ->
        str

      :asc_nulls_last ->
        [str | " ASC NULLS LAST"]

      :asc_nulls_first ->
        [str | " ASC NULLS FIRST"]

      :desc ->
        [str | " DESC"]

      :desc_nulls_last ->
        [str | " DESC NULLS LAST"]

      :desc_nulls_first ->
        [str | " DESC NULLS FIRST"]

      _ ->
        raise Ecto.QueryError,
          query: query,
          message: "#{dir} is not supported in ORDER BY in SQLite3"
    end
  end

  def limit(%{limit: nil}, _sources), do: []

  def limit(%{limit: %{expr: expression}} = query, sources) do
    [" LIMIT " | expr(expression, sources, query)]
  end

  def offset(%{offset: nil}, _sources), do: []

  def offset(%{offset: %QueryExpr{expr: expression}} = query, sources) do
    [" OFFSET " | expr(expression, sources, query)]
  end

  defp combinations(%{combinations: combinations}, as_prefix) do
    Enum.map(combinations, &combination(&1, as_prefix))
  end

  defp combination({:union, query}, as_prefix), do: [" UNION ", all(query, as_prefix)]

  defp combination({:union_all, query}, as_prefix),
    do: [" UNION ALL ", all(query, as_prefix)]

  defp combination({:except, query}, as_prefix), do: [" EXCEPT ", all(query, as_prefix)]

  defp combination({:intersect, query}, as_prefix),
    do: [" INTERSECT ", all(query, as_prefix)]

  defp combination({:except_all, query}, _) do
    raise Ecto.QueryError,
      query: query,
      message: "SQLite3 does not support EXCEPT ALL"
  end

  defp combination({:intersect_all, query}, _) do
    raise Ecto.QueryError,
      query: query,
      message: "SQLite3 does not INTERSECT ALL"
  end

  def lock(query, _sources) do
    raise Ecto.QueryError,
      query: query,
      message: "SQLite3 does not support locks"
  end

  defp boolean(_name, [], _sources, _query), do: []

  defp boolean(name, [%{expr: expression, op: op} | query_exprs], sources, query) do
    [
      name,
      Enum.reduce(query_exprs, {op, paren_expr(expression, sources, query)}, fn
        %BooleanExpr{expr: expression, op: op}, {op, acc} ->
          {op, [acc, operator_to_boolean(op) | paren_expr(expression, sources, query)]}

        %BooleanExpr{expr: expression, op: op}, {_, acc} ->
          {op,
           [
             ?(,
             acc,
             ?),
             operator_to_boolean(op) | paren_expr(expression, sources, query)
           ]}
      end)
      |> elem(1)
    ]
  end

  defp operator_to_boolean(:and), do: " AND "
  defp operator_to_boolean(:or), do: " OR "

  defp parens_for_select([first_expr | _] = expression) do
    if is_binary(first_expr) and String.match?(first_expr, ~r/^\s*select/i) do
      [?(, expression, ?)]
    else
      expression
    end
  end

  defp paren_expr(expression, sources, query) do
    [?(, expr(expression, sources, query), ?)]
  end

  defp top_level_expr(%Ecto.SubQuery{query: query}, sources, parent_query) do
    combinations =
      Enum.map(query.combinations, fn {type, combination_query} ->
        {type, put_in(combination_query.aliases[@parent_as], {parent_query, sources})}
      end)

    query = put_in(query.combinations, combinations)
    query = put_in(query.aliases[@parent_as], {parent_query, sources})
    [all(query, subquery_as_prefix(sources))]
  end

  defp top_level_expr(other, sources, parent_query) do
    expr(other, sources, parent_query)
  end

  ##
  ## Expression generation
  ##

  defp expr({:^, [], [_ix]}, _sources, _query) do
    ~c"?"
  end

  # workaround for the fact that SQLite3 as of 3.35.4 does not support specifying table
  # in the returning clause. when a later release adds the ability, this code can be deleted
  defp expr(
         {{:., _, [{:parent_as, _, [{:&, _, [_idx]}]}, field]}, _, []},
         _sources,
         %{returning: true}
       )
       when is_atom(field) do
    quote_name(field)
  end

  # workaround for the fact that SQLite3 as of 3.35.4 does not support specifying table
  # in the returning clause. when a later release adds the ability, this code can be deleted
  defp expr({{:., _, [{:&, _, [_idx]}, field]}, _, []}, _sources, %{returning: true})
       when is_atom(field) do
    quote_name(field)
  end

  defp expr({{:., _, [{:parent_as, _, [as]}, field]}, _, []}, _sources, query)
       when is_atom(field) do
    {ix, sources} = get_parent_sources_ix(query, as)
    {_, name, _} = elem(sources, ix)
    [name, ?. | quote_name(field)]
  end

  defp expr({{:., _, [{:&, _, [idx]}, field]}, _, []}, sources, _query)
       when is_atom(field) do
    {_, name, _} = elem(sources, idx)
    [name, ?. | quote_name(field)]
  end

  defp expr({:&, _, [idx]}, sources, _query) do
    {_, source, _} = elem(sources, idx)
    source
  end

  defp expr({:in, _, [_left, "[]"]}, _sources, _query) do
    "0"
  end

  defp expr({:in, _, [_left, []]}, _sources, _query) do
    "0"
  end

  defp expr({:in, _, [left, right]}, sources, query) when is_list(right) do
    args = Enum.map_intersperse(right, ?,, &expr(&1, sources, query))
    [expr(left, sources, query), " IN (", args, ?)]
  end

  defp expr({:in, _, [_, {:^, _, [_, 0]}]}, _sources, _query) do
    "0"
  end

  defp expr({:in, _, [left, {:^, _, [_, len]}]}, sources, query) do
    args = Enum.intersperse(List.duplicate(??, len), ?,)
    [expr(left, sources, query), " IN (", args, ?)]
  end

  defp expr({:in, _, [left, %Ecto.SubQuery{} = subquery]}, sources, query) do
    [expr(left, sources, query), " IN ", expr(subquery, sources, query)]
  end

  # Super Hack to handle arrays in json
  defp expr({:in, _, [left, right]}, sources, query) do
    [
      expr(left, sources, query),
      " IN (SELECT value FROM JSON_EACH(",
      expr(right, sources, query),
      ?),
      ?)
    ]
  end

  defp expr({:is_nil, _, [arg]}, sources, query) do
    [expr(arg, sources, query) | " IS NULL"]
  end

  defp expr({:not, _, [expression]}, sources, query) do
    ["NOT (", expr(expression, sources, query), ?)]
  end

  defp expr({:filter, _, [agg, filter]}, sources, query) do
    aggregate = expr(agg, sources, query)
    [aggregate, " FILTER (WHERE ", expr(filter, sources, query), ?)]
  end

  defp expr(%Ecto.SubQuery{query: query}, sources, parent_query) do
    combinations =
      Enum.map(query.combinations, fn {type, combination_query} ->
        {type, put_in(combination_query.aliases[@parent_as], {parent_query, sources})}
      end)

    query = put_in(query.combinations, combinations)
    query = put_in(query.aliases[@parent_as], {parent_query, sources})
    [?(, all(query, subquery_as_prefix(sources)), ?)]
  end

  defp expr({:fragment, _, [kw]}, _sources, query)
       when is_list(kw) or tuple_size(kw) == 3 do
    raise Ecto.QueryError,
      query: query,
      message: "SQLite3 adapter does not support keyword or interpolated fragments"
  end

  defp expr({:fragment, _, parts}, sources, query) do
    parts
    |> Enum.map(fn
      {:raw, part} -> part
      {:expr, expression} -> expr(expression, sources, query)
    end)
    |> parens_for_select
  end

  defp expr({:values, _, _}, _, _query) do
    raise ArgumentError, "SQLite3 adapter does not support values lists"
  end

  defp expr({:literal, _, [literal]}, _sources, _query) do
    quote_name(literal)
  end

  defp expr({:splice, _, [{:^, _, [_, length]}]}, _sources, _query) do
    Enum.intersperse(List.duplicate(??, length), ?,)
  end

  defp expr({:selected_as, _, [name]}, _sources, _query) do
    [quote_name(name)]
  end

  defp expr({:datetime_add, _, [datetime, count, interval]}, sources, query) do
    format =
      case Application.get_env(:ecto_sqlite3, :datetime_type) do
        :text_datetime ->
          "%Y-%m-%d %H:%M:%f000Z"

        _ ->
          "%Y-%m-%dT%H:%M:%f000Z"
      end

    [
      "CAST (",
      "strftime('#{format}'",
      ",",
      expr(datetime, sources, query),
      ",",
      interval(count, interval, sources),
      ") AS TEXT)"
    ]
  end

  defp expr({:date_add, _, [date, count, interval]}, sources, query) do
    [
      "CAST (",
      "strftime('%Y-%m-%d'",
      ",",
      expr(date, sources, query),
      ",",
      interval(count, interval, sources),
      ") AS TEXT)"
    ]
  end

  defp expr({:ilike, _, [_, _]}, _sources, query) do
    raise Ecto.QueryError,
      query: query,
      message: "ilike is not supported by SQLite3"
  end

  defp expr({:over, _, [agg, name]}, sources, query) when is_atom(name) do
    [expr(agg, sources, query), " OVER " | quote_name(name)]
  end

  defp expr({:over, _, [agg, kw]}, sources, query) do
    [expr(agg, sources, query), " OVER " | window_exprs(kw, sources, query)]
  end

  defp expr({:{}, _, elems}, sources, query) do
    [?(, Enum.map_intersperse(elems, ?,, &expr(&1, sources, query)), ?)]
  end

  defp expr({:count, _, []}, _sources, _query), do: "count(*)"

  defp expr({:count, _, [{:&, _, [_]}]}, _sources, query) do
    raise Ecto.QueryError,
      query: query,
      message: "The argument to `count/1` must be a column in SQLite3"
  end

  defp expr({:json_extract_path, _, [expr, path]}, sources, query) do
    path =
      Enum.map(path, fn
        binary when is_binary(binary) ->
          [?., escape_json_key(binary)]

        integer when is_integer(integer) ->
          "[#{integer}]"
      end)

    ["json_extract(", expr(expr, sources, query), ", '$", path, "')"]
  end

  defp expr({:exists, _, [subquery]}, sources, query) do
    ["exists", expr(subquery, sources, query)]
  end

  defp expr({fun, _, args}, sources, query) when is_atom(fun) and is_list(args) do
    {modifier, args} =
      case args do
        [_rest, :distinct] ->
          raise Ecto.QueryError,
            query: query,
            message: "Distinct not supported in expressions"

        _ ->
          {[], args}
      end

    case handle_call(fun, length(args)) do
      {:binary_op, op} ->
        [left, right] = args
        [op_to_binary(left, sources, query), op | op_to_binary(right, sources, query)]

      {:fun, fun} ->
        [
          fun,
          ?(,
          modifier,
          Enum.map_intersperse(args, ", ", &expr(&1, sources, query)),
          ?)
        ]
    end
  end

  # TODO It technically is, its just a json array, so we *could* support it
  defp expr(list, _sources, query) when is_list(list) do
    raise Ecto.QueryError,
      query: query,
      message: "Array literals are not supported by SQLite3"
  end

  defp expr(%Decimal{} = decimal, _sources, _query) do
    Decimal.to_string(decimal, :normal)
  end

  defp expr(%Ecto.Query.Tagged{value: binary, type: :binary}, _sources, _query)
       when is_binary(binary) do
    hex = Base.encode16(binary, case: :lower)
    [?x, ?', hex, ?']
  end

  defp expr(%Ecto.Query.Tagged{value: expr, type: :binary_id}, sources, query) do
    case Application.get_env(:ecto_sqlite3, :binary_id_type, :string) do
      :string ->
        ["CAST(", expr(expr, sources, query), " AS ", column_type(:string, query), ?)]

      :binary ->
        [expr(expr, sources, query)]
    end
  end

  defp expr(%Ecto.Query.Tagged{value: expr, type: :uuid}, sources, query) do
    case Application.get_env(:ecto_sqlite3, :uuid_type, :string) do
      :string ->
        ["CAST(", expr(expr, sources, query), " AS ", column_type(:string, query), ?)]

      :binary ->
        [expr(expr, sources, query)]
    end
  end

  defp expr(%Ecto.Query.Tagged{value: other, type: type}, sources, query)
       when type in [:decimal, :float] do
    ["CAST(", expr(other, sources, query), " AS REAL)"]
  end

  defp expr(%Ecto.Query.Tagged{value: other, type: type}, sources, query) do
    ["CAST(", expr(other, sources, query), " AS ", column_type(type, query), ?)]
  end

  defp expr(nil, _sources, _query), do: "NULL"
  defp expr(true, _sources, _query), do: "1"
  defp expr(false, _sources, _query), do: "0"

  defp expr(literal, _sources, _query) when is_binary(literal) do
    [?', escape_string(literal), ?']
  end

  defp expr(literal, _sources, _query) when is_integer(literal) do
    Integer.to_string(literal)
  end

  defp expr(literal, _sources, _query) when is_float(literal) do
    ["CAST(", Float.to_string(literal), " AS REAL)"]
  end

  defp expr(expr, _sources, query) do
    raise Ecto.QueryError,
      query: query,
      message: "unsupported expression #{inspect(expr)}"
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

  defp op_to_binary({op, _, [_, _]} = expression, sources, query)
       when op in @binary_ops do
    paren_expr(expression, sources, query)
  end

  defp op_to_binary({:is_nil, _, [_]} = expression, sources, query) do
    paren_expr(expression, sources, query)
  end

  defp op_to_binary(expression, sources, query) do
    expr(expression, sources, query)
  end

  def create_names(query) do
    create_names(query, [])
  end

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
    Enum.map_intersperse(columns, ", ", &column_definition(table, &1))
  end

  defp column_definition(table, {:add, name, %Reference{} = ref, opts}) do
    [
      quote_name(name),
      ?\s,
      column_type(ref.type, opts),
      column_options(table, ref.type, opts),
      reference_expr(ref, table, name)
    ]
  end

  defp column_definition(table, {:add, name, type, opts}) do
    [
      quote_name(name),
      ?\s,
      column_type(type, opts),
      column_options(table, type, opts)
    ]
  end

  defp column_change(table, {:add, name, %Reference{} = ref, opts}) do
    [
      "ADD COLUMN ",
      quote_name(name),
      ?\s,
      column_type(ref.type, opts),
      column_options(table, ref.type, opts),
      reference_expr(ref, table, name)
    ]
  end

  # If we are adding a DATETIME column with the NOT NULL constraint, SQLite
  # will force us to give it a DEFAULT value. The only default value
  # that makes sense is CURRENT_TIMESTAMP, but when adding a column to a
  # table, defaults must be constant values.
  #
  # Therefore the best option is just to remove the NOT NULL constraint when
  # we add new datetime columns.
  defp column_change(table, {:add, name, type, opts})
       when type in [:utc_datetime, :naive_datetime] do
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
    raise ArgumentError, "ALTER COLUMN not supported by SQLite3"
  end

  defp column_change(table, {:remove, name, _type, _opts}) do
    column_change(table, {:remove, name})
  end

  defp column_change(_table, {:remove, name}) do
    [
      "DROP COLUMN ",
      quote_name(name)
    ]
  end

  defp column_change(_table, _) do
    raise ArgumentError, "Not supported by SQLite3"
  end

  defp column_options(table, type, opts) do
    default = Keyword.fetch(opts, :default)
    null = Keyword.get(opts, :null)
    pk = table.primary_key != :composite and Keyword.get(opts, :primary_key, false)
    collate = Keyword.get(opts, :collate)
    check = Keyword.get(opts, :check)

    [
      default_expr(default),
      null_expr(null),
      collate_expr(collate),
      check_expr(check),
      pk_expr(pk, type)
    ]
  end

  defp check_expr(nil), do: []

  defp check_expr(%{name: name, expr: expr}),
    do: [" CONSTRAINT ", name, " CHECK (", expr, ")"]

  defp collate_expr(nil), do: []

  defp collate_expr(type) when is_atom(type),
    do: type |> Atom.to_string() |> collate_expr()

  defp collate_expr(type), do: [" COLLATE ", String.upcase(type)]

  defp null_expr(false), do: " NOT NULL"
  defp null_expr(true), do: " NULL"
  defp null_expr(_), do: []

  defp default_expr({:ok, nil}) do
    " DEFAULT NULL"
  end

  defp default_expr({:ok, literal}) when is_binary(literal) do
    [" DEFAULT '", escape_string(literal), ?']
  end

  defp default_expr({:ok, literal}) when is_number(literal) or is_boolean(literal) do
    [" DEFAULT ", to_string(literal)]
  end

  defp default_expr({:ok, {:fragment, expression}}) do
    [" DEFAULT ", expression]
  end

  defp default_expr({:ok, value}) when is_map(value) or is_list(value) do
    library = Application.get_env(:ecto_sqlite3, :json_library, Jason)
    expression = IO.iodata_to_binary(library.encode_to_iodata!(value))

    [" DEFAULT ('", escape_string(expression), "')"]
  end

  defp default_expr(:error), do: []

  defp index_expr(literal) when is_binary(literal), do: literal
  defp index_expr(literal), do: quote_name(literal)

  defp pk_expr(true, type) when type in [:serial, :bigserial],
    do: " PRIMARY KEY AUTOINCREMENT"

  defp pk_expr(true, _), do: " PRIMARY KEY"
  defp pk_expr(_, _), do: []

  defp options_expr(nil), do: []

  defp options_expr(options) when is_list(options) do
    raise ArgumentError, "SQLite3 adapter does not support keyword lists in :options"
  end

  defp options_expr(options), do: [?\s, to_string(options)]

  # composite FK is handled at table level
  defp reference_expr(%Reference{with: [_]}, _table, _name), do: []

  defp reference_expr(%Reference{} = ref, table, name) do
    [
      " CONSTRAINT ",
      reference_name(ref, table, name),
      " REFERENCES ",
      quote_table(ref.prefix || table.prefix, ref.table),
      ?(,
      quote_name(ref.column),
      ?),
      reference_on_delete(ref.on_delete),
      reference_on_update(ref.on_update)
    ]
  end

  defp reference_name(%Reference{name: nil}, table, column) do
    quote_name("#{table.name}_#{column}_fkey")
  end

  defp reference_name(%Reference{name: name}, _table, _column) do
    quote_name(name)
  end

  defp reference_on_delete(:nilify_all), do: " ON DELETE SET NULL"
  defp reference_on_delete(:default_all), do: " ON DELETE SET DEFAULT"
  defp reference_on_delete(:delete_all), do: " ON DELETE CASCADE"
  defp reference_on_delete(:restrict), do: " ON DELETE RESTRICT"
  defp reference_on_delete(_), do: []

  defp reference_on_update(:nilify_all), do: " ON UPDATE SET NULL"
  defp reference_on_update(:default_all), do: " ON UPDATE SET DEFAULT"
  defp reference_on_update(:update_all), do: " ON UPDATE CASCADE"
  defp reference_on_update(:restrict), do: " ON UPDATE RESTRICT"
  defp reference_on_update(_), do: []

  defp returning(%{select: nil}, _sources), do: []

  defp returning(%{select: %{fields: fields}} = query, sources) do
    [
      " RETURNING " | select_fields(fields, sources, Map.put(query, :returning, true))
    ]
  end

  defp returning([]), do: []

  defp returning(returning) do
    [
      " RETURNING " | quote_names(returning)
    ]
  end

  ##
  ## Helpers
  ##

  defp composite_pk_definition(%Table{} = table, columns) do
    pks =
      Enum.reduce(columns, [], fn {_, name, _, opts}, pk_acc ->
        case Keyword.get(opts, :primary_key, false) do
          true -> [name | pk_acc]
          false -> pk_acc
        end
      end)

    if length(pks) > 1 do
      composite_pk_expr = pks |> Enum.reverse() |> Enum.map_join(",", &quote_name/1)

      {
        %{table | primary_key: :composite},
        ", PRIMARY KEY (" <> composite_pk_expr <> ")"
      }
    else
      {table, ""}
    end
  end

  defp composite_fk_definitions(%Table{} = table, columns) do
    composite_fk_cols =
      columns
      |> Enum.filter(fn c ->
        case c do
          {_op, _name, %Reference{with: [_]}, _opts} -> true
          _ -> false
        end
      end)

    Enum.map(composite_fk_cols, &composite_fk_definition(table, &1))
  end

  defp composite_fk_definition(table, {_op, name, ref, _opts}) do
    {current_columns, reference_columns} = Enum.unzip([{name, ref.column} | ref.with])

    [
      ", FOREIGN KEY (",
      quote_names(current_columns),
      ") REFERENCES ",
      quote_table(ref.prefix || table.prefix, ref.table),
      ?(,
      quote_names(reference_columns),
      ?),
      reference_on_delete(ref.on_delete),
      reference_on_update(ref.on_update)
    ]
  end

  defp get_source(query, sources, ix, source) do
    {expression, name, _schema} = elem(sources, ix)
    {expression || expr(source, sources, query), name}
  end

  defp get_parent_sources_ix(query, as) do
    case query.aliases[@parent_as] do
      {%{aliases: %{^as => ix}}, sources} -> {ix, sources}
      {%{} = parent, _sources} -> get_parent_sources_ix(parent, as)
    end
  end

  defp quote_names(names), do: Enum.map_intersperse(names, ?,, &quote_name/1)

  def quote_name(name), do: quote_entity(name)

  def quote_table(table), do: quote_entity(table)

  defp quote_table(nil, name), do: quote_entity(name)

  defp quote_table(prefix, _name) when is_atom(prefix) or is_binary(prefix) do
    raise ArgumentError, "SQLite3 does not support table prefixes"
  end

  defp quote_table(_, name), do: quote_entity(name)

  defp quote_entity(val) when is_atom(val) do
    quote_entity(Atom.to_string(val))
  end

  defp quote_entity(val), do: [[?", val, ?"]]

  defp intersperse_reduce(list, separator, user_acc, reducer, acc \\ [])

  defp intersperse_reduce([], _separator, user_acc, _reducer, acc),
    do: {acc, user_acc}

  defp intersperse_reduce([item], _separator, user_acc, reducer, acc) do
    {item, user_acc} = reducer.(item, user_acc)
    {[acc | item], user_acc}
  end

  defp intersperse_reduce([item | rest], separator, user_acc, reducer, acc) do
    {item, user_acc} = reducer.(item, user_acc)
    intersperse_reduce(rest, separator, user_acc, reducer, [acc, item, separator])
  end

  defp if_do(condition, value) do
    if condition, do: value, else: []
  end

  defp escape_string(value) when is_binary(value) do
    value
    |> :binary.replace("'", "''", [:global])
    |> :binary.replace("\\", "\\\\", [:global])
  end

  defp escape_json_key(value) when is_binary(value) do
    value
    |> escape_string()
    |> :binary.replace("\"", "\\\"", [:global])
  end
end
