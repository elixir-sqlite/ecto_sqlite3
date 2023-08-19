defmodule EctoSQLite3.Schemas.Vec3f do
  @moduledoc false

  use Ecto.Schema

  schema "vec3f" do
    field(:x, :float)
    field(:y, :float)
    field(:z, :float)
  end
end
