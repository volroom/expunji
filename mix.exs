defmodule Expunji.MixProject do
  use Mix.Project

  def project do
    [
      app: :expunji,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Expunji.Application, []}
    ]
  end

  defp deps do
    [
      {:cachex, "~> 3.4"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14.1", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
