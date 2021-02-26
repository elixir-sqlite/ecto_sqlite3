defmodule Ecto.Integration.User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
  end
end

defmodule Ecto.Integration.Comment do
  use Ecto.Schema

  schema "comments" do
    field(:body, :string)

    has_one(:author, Ecto.Integration.User)
  end
end

defmodule Ecto.Integration.Post do
  use Ecto.Schema

  schema "posts" do
    field(:title, :string)
    field(:body, :string)

    has_one(:author, Ecto.Integration.User)
    has_many(:comments, Ecto.Integration.Comment)
  end
end
