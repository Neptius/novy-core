defmodule NovyCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :novy_core,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {NovyCore.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:argon2_elixir, "~> 3.0"},
      {:ecto, "~> 3.10"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:cachex, "~> 4.0"},
      {:finch, "~> 0.19"},
      {:jason, "~> 1.4"},
      {:hammer, "~> 7.0"},
      {:req, "~> 0.5.8"},
      {:elixir_uuid, "~> 1.2"},
      {:websockex, "~> 0.5.0", hex: :websockex_wt}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
