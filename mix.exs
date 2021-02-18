defmodule Exqlite.MixProject do
  use Mix.Project

  def project do
    [
      app: :exqlite,
      version: "0.1.0",
      elixir: "~> 1.11",
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_targets: ["all"],
      make_clean: ["clean"],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:db_connection, "~> 2.1"},
      {:decimal, "~> 2.0"},
      {:esqlite, "~> 0.4"},
      {:ecto_sql, "~> 3.5.4"},
      {:elixir_make, "~> 0.6", runtime: false},
      {:temp, "~> 0.4", only: [:test]}
    ]
  end
end
