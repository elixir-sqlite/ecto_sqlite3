defmodule Exqlite.MixProject do
  use Mix.Project

  def project do
    [
      app: :exqlite,
      version: "0.1.1",
      elixir: "~> 1.11",
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_targets: ["all"],
      make_clean: ["clean"],
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/warmwaffles/exqlite",
      homepage_url: "https://github.com/warmwaffles/exqlite",
      deps: deps(),
      package: package(),
      description: description()
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
      {:ecto_sql, "~> 3.5.4"},
      {:elixir_make, "~> 0.6", runtime: false},
      {:ex_doc, "~> 0.23.0", only: [:dev], runtime: false},
      {:temp, "~> 0.4", only: [:test]}
    ]
  end

  defp description do
    "An Sqlite3 Elixir library."
  end

  defp package do
    [
      name: "exqlite",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/warmwaffles/exqlite",
        "docs" => "https://hexdocs.pm/exqlite"
      }
    ]
  end
end
