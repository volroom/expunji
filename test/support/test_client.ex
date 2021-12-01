defmodule Expunji.TestClient do
  @moduledoc """
  Genserver acting as a DNS Client - used for testing
  """
  use GenServer

  alias Expunji.DNSUtils

  @client_socket_port Application.compile_env!(:expunji, :client_socket_port)

  def start_link, do: GenServer.start_link(__MODULE__, nil)

  @impl GenServer
  def init(_) do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])
    {:ok, %{socket: socket}}
  end

  def query_domain(pid, domain, type) do
    GenServer.call(pid, {:query_domain, domain, type})
  end

  @impl GenServer
  def handle_call({:query_domain, domain, type}, _, %{socket: socket} = state) do
    packet = DNSUtils.make_dns_query(domain, type)
    :ok = :gen_udp.send(socket, {127, 0, 0, 1}, @client_socket_port, packet)
    {:ok, response} = :gen_udp.recv(socket, 0)
    outcome = DNSUtils.get_query_outcome(response)

    {:reply, outcome, state}
  end
end
