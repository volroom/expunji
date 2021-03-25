defmodule Expunji.Application do
  @moduledoc false

  use Application

  alias Expunji.Server

  @impl true
  def start(_type, _args) do
    children = [
      Server
    ]

    opts = [strategy: :one_for_one, name: Expunji.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
