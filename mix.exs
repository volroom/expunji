defmodule Expunji.MixProject do
  use Mix.Project

  def project do
    [
      app: :expunji,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      applications: [:cachex],
      extra_applications: [:logger],
      mod: {Expunji.Application, []}
    ]
  end

  defp deps do
    [
      {:cachex, "~> 3.3"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end
end
