defmodule EctoSQLite3.Schemas.Schema2 do
  @moduledoc false

  use Ecto.Schema

  schema "schema2" do
    belongs_to(:post, EctoSQLite3.Schemas.Schema,
      references: :x,
      foreign_key: :z
    )
  end
end
