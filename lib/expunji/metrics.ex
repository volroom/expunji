defmodule Expunji.Metrics do
  @moduledoc """
  Custom metrics - query outcomes, table sizes
  """
  use Prometheus.Metric

  require Prometheus.Registry

  def setup do
    Counter.declare(name: :dns_queries_total, labels: [:outcome], help: "Total DNS queries")
    Gauge.declare(name: :hosts_table_rows, help: "Number of hosts loaded")
  end

  def log_query_outcome(outcome), do: Counter.inc(name: :dns_queries_total, labels: [outcome])

  def update_hosts_table_rows do
    rows = Keyword.fetch!(:ets.info(:hosts_table), :size)
    Gauge.set(:hosts_table_rows, rows)
  end
end
