defmodule EctoSQLite3.Schemas.Schema3 do
  @moduledoc false

  use Ecto.Schema

  schema "schema3" do
    field(:list1, {:array, :string})
    field(:list2, {:array, :integer})
    field(:binary, :binary)
  end
end
