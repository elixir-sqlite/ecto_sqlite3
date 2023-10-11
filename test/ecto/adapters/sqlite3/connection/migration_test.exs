defmodule Ecto.Adapters.SQLite3.Connection.MigrationTest do
  use ExUnit.Case, async: true

  import Ecto.Adapters.SQLite3.TestHelpers
  import Ecto.Migration, only: [table: 1, table: 2, index: 2, index: 3, constraint: 3]

  alias Ecto.Migration.Reference

  test "executing a string during migration" do
    assert execute_ddl("example") == ["example"]
  end

  test "create table" do
    create =
      {:create, table(:posts),
       [
         {:add, :name, :string, [default: "Untitled", size: 20, null: false]},
         {:add, :price, :numeric,
          [precision: 8, scale: 2, default: {:fragment, "expr"}]},
         {:add, :on_hand, :integer, [default: 0, null: true]},
         {:add, :is_active, :boolean, [default: true]},
         {:add, :tags, {:array, :string}, [default: []]},
         {:add, :languages, {:array, :string}, [default: ["pt", "es"]]},
         {:add, :limits, {:array, :integer}, [default: [100, 30_000]]}
       ]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE "posts" ("name" TEXT DEFAULT 'Untitled' NOT NULL,
             "price" NUMERIC DEFAULT expr,
             "on_hand" INTEGER DEFAULT 0 NULL,
             "is_active" INTEGER DEFAULT true,
             "tags" TEXT DEFAULT ('[]'),
             "languages" TEXT DEFAULT ('["pt","es"]'),
             "limits" TEXT DEFAULT ('[100,30000]'))
             """
             |> remove_newlines
           ]
  end

  test "create table with prefix" do
    create =
      {:create, table(:posts, prefix: :foo),
       [{:add, :category_0, %Reference{table: :categories}, []}]}

    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      execute_ddl(create)
    end
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
         {:add, :category_5, %Reference{table: :categories, on_update: :nothing}, []},
         {:add, :category_6, %Reference{table: :categories, on_update: :update_all},
          [null: false]},
         {:add, :category_7, %Reference{table: :categories, on_update: :nilify_all},
          []},
         {:add, :category_8,
          %Reference{
            table: :categories,
            on_delete: :nilify_all,
            on_update: :update_all
          }, [null: false]},
         {:add, :category_9, %Reference{table: :categories, on_delete: :restrict}, []},
         {:add, :category_10, %Reference{table: :categories, on_update: :restrict}, []}
       ]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE "posts" (\
             "id" INTEGER PRIMARY KEY AUTOINCREMENT, \
             "category_0" INTEGER CONSTRAINT "posts_category_0_fkey" REFERENCES "categories"("id"), \
             "category_1" INTEGER CONSTRAINT "foo_bar" REFERENCES "categories"("id"), \
             "category_2" INTEGER CONSTRAINT "posts_category_2_fkey" REFERENCES "categories"("id"), \
             "category_3" INTEGER NOT NULL CONSTRAINT "posts_category_3_fkey" REFERENCES "categories"("id") ON DELETE CASCADE, \
             "category_4" INTEGER CONSTRAINT "posts_category_4_fkey" REFERENCES "categories"("id") ON DELETE SET NULL, \
             "category_5" INTEGER CONSTRAINT "posts_category_5_fkey" REFERENCES "categories"("id"), \
             "category_6" INTEGER NOT NULL CONSTRAINT "posts_category_6_fkey" REFERENCES "categories"("id") ON UPDATE CASCADE, \
             "category_7" INTEGER CONSTRAINT "posts_category_7_fkey" REFERENCES "categories"("id") ON UPDATE SET NULL, \
             "category_8" INTEGER NOT NULL CONSTRAINT "posts_category_8_fkey" REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE, \
             "category_9" INTEGER CONSTRAINT "posts_category_9_fkey" REFERENCES "categories"("id") ON DELETE RESTRICT, \
             "category_10" INTEGER CONSTRAINT "posts_category_10_fkey" REFERENCES "categories"("id") ON UPDATE RESTRICT\
             )\
             """
           ]
  end

  test "create table with options" do
    create =
      {:create, table(:posts, options: "WITH FOO=BAR"),
       [
         {:add, :id, :serial, [primary_key: true]},
         {:add, :created_at, :naive_datetime, []}
       ]}

    assert execute_ddl(create) ==
             [
               ~s|CREATE TABLE "posts" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, "created_at" TEXT) WITH FOO=BAR|
             ]
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
             CREATE TABLE "posts" ("a" INTEGER, "b" INTEGER, "name" TEXT, PRIMARY KEY ("a","b"))
             """
             |> remove_newlines
           ]
  end

  test "create table with binary column and UTF-8 default" do
    create = {:create, table(:blobs), [{:add, :blob, :binary, [default: "foo"]}]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE "blobs" ("blob" BLOB DEFAULT 'foo')
             """
             |> remove_newlines
           ]
  end

  test "create table with binary column and hex blob literal default" do
    create = {:create, table(:blobs), [{:add, :blob, :binary, [default: "\\x666F6F"]}]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE "blobs" ("blob" BLOB DEFAULT '\\\\x666F6F')
             """
             |> remove_newlines
           ]
  end

  test "create table with binary column and hex blob literal null-byte" do
    create = {:create, table(:blobs), [{:add, :blob, :binary, [default: "\\\x00"]}]}

    assert execute_ddl(create) == [
             """
             CREATE TABLE "blobs" ("blob" BLOB DEFAULT '\\\\\x00')
             """
             |> remove_newlines
           ]
  end

  test "create table with a map column, and an empty map default" do
    create =
      {:create, table(:posts),
       [
         {:add, :a, :map, [default: %{}]}
       ]}

    assert execute_ddl(create) == [~s|CREATE TABLE "posts" ("a" TEXT DEFAULT ('{}'))|]
  end

  test "create table with a map column, and a map default with values" do
    create =
      {:create, table(:posts),
       [
         {:add, :a, :map, [default: %{foo: "bar", baz: "boom"}]}
       ]}

    assert [statement] = execute_ddl(create)

    # CREATE TABLE "posts" ("a" TEXT DEFAULT ('{"foo":"bar","baz":"boom"}'))
    assert statement =~ ~r|CREATE TABLE "posts" \("a" TEXT DEFAULT \(.*\)\)|
    assert statement =~ ~s("foo":"bar")
    assert statement =~ ~s("baz":"boom")
  end

  test "create table with a map column, and a string default" do
    create =
      {:create, table(:posts),
       [
         {:add, :a, :map, [default: ~s|{"foo":"bar","baz":"boom"}|]}
       ]}

    assert [statement] = execute_ddl(create)

    # CREATE TABLE "posts" ("a" TEXT DEFAULT '{"foo":"bar","baz":"boom"}')
    assert statement =~ ~r|CREATE TABLE "posts" \("a" TEXT DEFAULT '\{.*\}'\)|
    assert statement =~ ~s("foo":"bar")
    assert statement =~ ~s("baz":"boom")
  end

  test "create table with time columns" do
    create =
      {:create, table(:posts),
       [{:add, :published_at, :time, [precision: 3]}, {:add, :submitted_at, :time, []}]}

    assert execute_ddl(create) == [
             ~s|CREATE TABLE "posts" ("published_at" TEXT, "submitted_at" TEXT)|
           ]
  end

  test "create table with time_usec columns" do
    create =
      {:create, table(:posts),
       [
         {:add, :published_at, :time_usec, [precision: 3]},
         {:add, :submitted_at, :time_usec, []}
       ]}

    assert execute_ddl(create) == [
             ~s|CREATE TABLE "posts" ("published_at" TEXT, "submitted_at" TEXT)|
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
             ~s|CREATE TABLE "posts" ("published_at" TEXT, "submitted_at" TEXT)|
           ]
  end

  test "create table with utc_datetime_usec columns" do
    create =
      {:create, table(:posts),
       [
         {:add, :published_at, :utc_datetime_usec, [precision: 3]},
         {:add, :submitted_at, :utc_datetime_usec, []}
       ]}

    assert execute_ddl(create) == [
             ~s|CREATE TABLE "posts" ("published_at" TEXT, "submitted_at" TEXT)|
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
             ~s|CREATE TABLE "posts" ("published_at" TEXT, "submitted_at" TEXT)|
           ]
  end

  test "create table with naive_datetime_usec columns" do
    create =
      {:create, table(:posts),
       [
         {:add, :published_at, :naive_datetime_usec, [precision: 3]},
         {:add, :submitted_at, :naive_datetime_usec, []}
       ]}

    assert execute_ddl(create) == [
             ~s|CREATE TABLE "posts" ("published_at" TEXT, "submitted_at" TEXT)|
           ]
  end

  test "create table with an unsupported type" do
    create =
      {:create, table(:posts),
       [
         {:add, :a, {:a, :b, :c}, [default: %{}]}
       ]}

    assert_raise ArgumentError,
                 "unsupported type `{:a, :b, :c}`. " <>
                   "The type can either be an atom, a string or a tuple of the form " <>
                   "`{:map, t}` or `{:array, t}` where `t` itself follows the same conditions.",
                 fn -> execute_ddl(create) end
  end

  test "drop table" do
    drop = {:drop, table(:posts)}
    assert execute_ddl(drop) == [~s|DROP TABLE "posts"|]
  end

  test "drop table with prefix" do
    drop = {:drop, table(:posts, prefix: :foo)}

    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      execute_ddl(drop)
    end
  end

  test "alter table" do
    alter =
      {:alter, table(:posts),
       [
         {:add, :title, :string, [default: "Untitled", size: 100, null: false]},
         {:add, :author_id, %Reference{table: :author}, []},
         {:add, :category_id, %Reference{table: :categories, validate: false}, []},
         {:remove, :summary},
         {:remove, :body, :text, []},
         {:remove, :space_id, %Reference{table: :author}, []}
       ]}

    assert execute_ddl(alter) == [
             ~s|ALTER TABLE "posts" ADD COLUMN "title" TEXT DEFAULT 'Untitled' NOT NULL|,
             ~s|ALTER TABLE "posts" ADD COLUMN "author_id" INTEGER CONSTRAINT "posts_author_id_fkey" REFERENCES "author"("id")|,
             ~s|ALTER TABLE "posts" ADD COLUMN "category_id" INTEGER CONSTRAINT "posts_category_id_fkey" REFERENCES "categories"("id")|,
             ~s|ALTER TABLE "posts" DROP COLUMN "summary"|,
             ~s|ALTER TABLE "posts" DROP COLUMN "body"|,
             ~s|ALTER TABLE "posts" DROP COLUMN "space_id"|
           ]
  end

  test "alter table with prefix" do
    alter =
      {:alter, table(:posts, prefix: :foo),
       [{:add, :author_id, %Reference{table: :author}, []}]}

    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      execute_ddl(alter)
    end
  end

  test "alter table with serial primary key" do
    alter = {:alter, table(:posts), [{:add, :my_pk, :serial, [primary_key: true]}]}

    assert execute_ddl(alter) == [
             """
             ALTER TABLE "posts"
             ADD COLUMN "my_pk" INTEGER PRIMARY KEY AUTOINCREMENT
             """
             |> remove_newlines
           ]
  end

  test "alter table with bigserial primary key" do
    alter = {:alter, table(:posts), [{:add, :my_pk, :bigserial, [primary_key: true]}]}

    assert execute_ddl(alter) == [
             """
             ALTER TABLE "posts"
             ADD COLUMN "my_pk" INTEGER PRIMARY KEY AUTOINCREMENT
             """
             |> remove_newlines
           ]
  end

  test "create index" do
    create = {:create, index(:posts, [:category_id, :permalink])}

    assert execute_ddl(create) ==
             [
               ~s|CREATE INDEX "posts_category_id_permalink_index" ON "posts" ("category_id", "permalink")|
             ]

    create = {:create, index(:posts, ["lower(permalink)"], name: "posts$main")}

    assert execute_ddl(create) ==
             [~s|CREATE INDEX "posts$main" ON "posts" (lower(permalink))|]
  end

  test "create index with prefix" do
    create = {:create, index(:posts, [:category_id, :permalink], prefix: :foo)}

    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      execute_ddl(create)
    end

    create =
      {:create, index(:posts, ["lower(permalink)"], name: "posts$main", prefix: :foo)}

    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      execute_ddl(create)
    end
  end

  test "create index with comment" do
    create = {:create, index(:posts, [:category_id, :permalink], comment: "comment")}

    assert execute_ddl(create) == [
             """
             CREATE INDEX "posts_category_id_permalink_index" \
             ON "posts" ("category_id", "permalink")\
             """
           ]

    # NOTE: Comments are not supported by SQLite. DDL query generator will ignore them.
  end

  test "create unique index" do
    create = {:create, index(:posts, [:permalink], unique: true)}

    assert execute_ddl(create) ==
             [~s|CREATE UNIQUE INDEX "posts_permalink_index" ON "posts" ("permalink")|]
  end

  test "create unique index with condition" do
    create = {:create, index(:posts, [:permalink], unique: true, where: "public IS 1")}

    assert execute_ddl(create) ==
             [
               ~s|CREATE UNIQUE INDEX "posts_permalink_index" ON "posts" ("permalink") WHERE public IS 1|
             ]

    create = {:create, index(:posts, [:permalink], unique: true, where: :public)}

    assert execute_ddl(create) ==
             [
               ~s|CREATE UNIQUE INDEX "posts_permalink_index" ON "posts" ("permalink") WHERE public|
             ]
  end

  test "create index with include fields" do
    create = {:create, index(:posts, [:permalink], unique: true, include: [:public])}

    assert_raise ArgumentError, fn ->
      execute_ddl(create)
    end
  end

  test "create unique index with nulls_distinct option" do
    create = {:create, index(:posts, [:permalink], unique: true, nulls_distinct: true)}

    assert_raise ArgumentError, fn ->
      execute_ddl(create)
    end
  end

  test "create index concurrently not supported" do
    index = index(:posts, [:permalink])
    create = {:create, %{index | concurrently: true}}

    assert_raise ArgumentError, fn ->
      execute_ddl(create)
    end
  end

  test "create an index using a different type" do
    create = {:create, index(:posts, [:permalink], using: :hash)}

    assert_raise ArgumentError, fn ->
      execute_ddl(create)
    end
  end

  test "create an index without recursively creating indexes on partitions" do
    create = {:create, index(:posts, [:permalink], only: true)}

    assert_raise ArgumentError, fn ->
      execute_ddl(create)
    end
  end

  test "drop index" do
    drop = {:drop, index(:posts, [:id], name: "posts$main")}
    assert execute_ddl(drop) == [~s|DROP INDEX "posts$main"|]
  end

  test "drop index with prefix" do
    drop = {:drop, index(:posts, [:id], name: "posts$main", prefix: :foo), :restrict}

    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      execute_ddl(drop)
    end
  end

  test "drop index concurrently not supported" do
    index = index(:posts, [:id], name: "posts$main")

    assert_raise ArgumentError, fn ->
      drop = {:drop, %{index | concurrently: true}}
      execute_ddl(drop)
    end
  end

  test "drop constraint" do
    assert_raise ArgumentError,
                 ~r/SQLite3 does not support ALTER TABLE DROP CONSTRAINT./,
                 fn ->
                   execute_ddl(
                     {:drop,
                      constraint(:products, "price_must_be_positive", prefix: :foo),
                      :restrict}
                   )
                 end
  end

  test "drop_if_exists constraint" do
    assert_raise ArgumentError,
                 ~r/SQLite3 does not support ALTER TABLE DROP CONSTRAINT./,
                 fn ->
                   execute_ddl(
                     {:drop_if_exists,
                      constraint(:products, "price_must_be_positive", prefix: :foo),
                      :restrict}
                   )
                 end
  end

  test "rename table" do
    rename = {:rename, table(:posts), table(:new_posts)}
    assert execute_ddl(rename) == [~s|ALTER TABLE "posts" RENAME TO "new_posts"|]
  end

  test "rename table with prefix" do
    rename = {:rename, table(:posts, prefix: :foo), table(:new_posts, prefix: :foo)}

    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      execute_ddl(rename)
    end
  end

  test "rename column" do
    rename = {:rename, table(:posts), :given_name, :first_name}

    assert execute_ddl(rename) == [
             ~s|ALTER TABLE "posts" RENAME COLUMN "given_name" TO "first_name"|
           ]
  end

  test "rename column in prefixed table" do
    rename = {:rename, table(:posts, prefix: :foo), :given_name, :first_name}

    assert_raise ArgumentError, "SQLite3 does not support table prefixes", fn ->
      execute_ddl(rename)
    end
  end

  test "autoincrement support" do
    serial = {:create, table(:posts), [{:add, :id, :serial, [primary_key: true]}]}
    bigserial = {:create, table(:posts), [{:add, :id, :bigserial, [primary_key: true]}]}
    id = {:create, table(:posts), [{:add, :id, :id, [primary_key: true]}]}
    integer = {:create, table(:posts), [{:add, :id, :integer, [primary_key: true]}]}

    assert execute_ddl(serial) == [
             ~s/CREATE TABLE "posts" ("id" INTEGER PRIMARY KEY AUTOINCREMENT)/
           ]

    assert execute_ddl(bigserial) == [
             ~s/CREATE TABLE "posts" ("id" INTEGER PRIMARY KEY AUTOINCREMENT)/
           ]

    assert execute_ddl(id) == [~s/CREATE TABLE "posts" ("id" INTEGER PRIMARY KEY)/]
    assert execute_ddl(integer) == [~s/CREATE TABLE "posts" ("id" INTEGER PRIMARY KEY)/]
  end
end
