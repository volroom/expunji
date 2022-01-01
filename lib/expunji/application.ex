defmodule Expunji.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    ExpunjiWeb.MetricsExporter.setup()
    Expunji.Metrics.setup()
    children = get_children(Application.fetch_env!(:expunji, :env))

    opts = [strategy: :one_for_one, name: Expunji.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_children(:test) do
    [{Cachex, name: :dns_cache}]
  end

  defp get_children(_) do
    [{Cachex, name: :dns_cache}, ExpunjiWeb.Endpoint, Expunji.Server]
  end
end
