defmodule Exqlite.Integration.User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
  end
end

defmodule Exqlite.Integration.Comment do
  use Ecto.Schema

  schema "comments" do
    field(:body, :string)

    has_one(:author, Exqlite.Integration.User)
  end
end

defmodule Exqlite.Integration.Post do
  use Ecto.Schema

  schema "posts" do
    field(:title, :string)
    field(:body, :string)

    has_one(:author, Exqlite.Integration.User)
    has_many(:comments, Exqlite.Integration.Comment)
  end
end
