defmodule Expunji.Application do
  @moduledoc false

  use Application

  @children Application.compile_env!(:expunji, :children)

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Expunji.Supervisor]
    Supervisor.start_link(@children, opts)
  end
end
