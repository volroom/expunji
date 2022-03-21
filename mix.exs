defmodule Expunji.MixProject do
  use Mix.Project

  def project do
    [
      app: :expunji,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      elixirc_options: [warnings_as_errors: true],
      elixirc_paths: elixirc_paths(Mix.env()),
      xref: [exclude: [:mnesia]]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :plug, :mnesia],
      mod: {Expunji.Application, []}
    ]
  end

  defp deps do
    [
      {:cachex, "~> 3.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14.4", only: :test},
      {:jason, "~> 1.3"},
      {:mox, "~> 1.0", only: :test},
      {:phoenix, "~> 1.6"},
      {:phoenix_html, "~> 3.2"},
      {:plug, "~> 1.13"},
      {:plug_cowboy, "~> 2.5"},
      {:prometheus, "~> 4.8"},
      {:prometheus_plugs, "~> 1.1"}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end
