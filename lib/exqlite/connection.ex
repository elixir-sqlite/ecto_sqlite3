defmodule Exqlite.Connection do

  @doc """
  This module imlements connection details as defined in DBProtocol.

  Notes:
    - we try to closely follow structure and naming convention of myxql.
    - sqlite thrives when there are many small conventions, so we may not implement
      some strategies employed by other adapters. See https://sqlite.org/np1queryprob.html
  """

  use DBConnection
  alias Exqlite.Sqlite3
  alias Exqlite.Error
  alias Exqlite.Result

  defstruct [
    :db
  ]

end
