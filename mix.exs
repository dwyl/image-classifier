defmodule App.MixProject do
  use Mix.Project

  def project do
    [
      app: :app,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        c: :test,
        coveralls: :test,
        "coveralls.json": :test,
        "coveralls.html": :test,
        t: :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {App.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.10"},
      {:phoenix_html, "~> 4.0.0"},
      {:phoenix_live_reload, "~> 1.4.1", only: :dev},
      {:phoenix_live_view, "~> 0.20.4"},
      {:heroicons, "~> 0.5.3"},
      {:floki, ">= 0.35.2", only: :test},
      {:esbuild, "~> 0.8.1", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7"},

      # HTTP Request
      {:httpoison, "~> 2.2"},
      {:req, "0.4.8"},
      {:mime, "~> 2.0.5"},
      {:ex_image_info, "~> 0.2.4"},
      {:gen_magic, "~> 1.1.1"},

      # DB
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.11"},
      {:postgrex, ">= 0.0.0"},

      # Bumblebee imports
      {:bumblebee, "~> 0.4.2"},
      {:exla, "~> 0.6.4"},
      # {:xla, "~> 0.6.0"},
      {:nx, "~> 0.6.4 "},
      {:hnswlib, "~> 0.1.4"},
      # {:hnswlib, git: "https://github.com/elixir-nx/hnswlib", override: true},

      # Image
      {:vix, "~> 0.26.0"},

      # Testing
      {:excoveralls, "~> 0.15", only: [:test, :dev]},
      {:mock, "~> 0.3.0", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test --seed 0"],
      t: ["test"],
      c: ["coveralls.html"],
      s: ["phx.server"]
    ]
  end
end
