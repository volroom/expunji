defmodule Expunji.Server do
  @moduledoc """
  Main server.
  Loads hosts files into ETS on startup.
  Accepts DNS requests and blocks them or passes through to real DNS server based on loaded hosts files.
  """

  use GenServer

  alias Expunji.DNSUtils

  @nameserver_socket_port 51234
  @hosts_table_name :hosts

  def start_link(_) do
    default_state = %{
      allowed_requests: 0,
      blocked_requests: 0,
      client_socket: nil,
      nameserver_socket: nil
    }

    GenServer.start_link(__MODULE__, default_state, name: __MODULE__)
  end

  def init(state) do
    :ets.new(@hosts_table_name, [:set, :named_table])
    load_hosts_into_ets()
    :logger.info("Opening sockets")
    {:ok, client_socket} = :gen_udp.open(53, [:binary, active: true])
    {:ok, nameserver_socket} = :gen_udp.open(@nameserver_socket_port, [:binary, active: false])
    :logger.info("Server up")

    {:ok, %{state | client_socket: client_socket, nameserver_socket: nameserver_socket}}
  end

  def get_stats() do
    GenServer.call(__MODULE__, :get_stats)
  end

  def reload_hosts() do
    GenServer.call(__MODULE__, :reload_hosts)
  end

  def handle_call(:get_stats, _from, state) do
    %{allowed_requests: allowed, blocked_requests: blocked} = state
    total = allowed + blocked
    allowed_perc = Float.round(allowed / total * 100, 2)
    blocked_perc = Float.round(blocked / total * 100, 2)

    :logger.info("""
    Allowed: #{allowed_perc}% (#{state.allowed_requests} requests)
    Blocked: #{blocked_perc}% (#{state.blocked_requests} requests)
    Total: #{total} requests
    """)

    {:reply, :ok, state}
  end

  def handle_call(:reload_hosts, _from, state) do
    load_hosts_into_ets()
    {:reply, :ok, state}
  end

  def handle_info({:udp, socket, client_ip, port, packet}, state) do
    record = DNSUtils.decode(packet)
    domain = DNSUtils.get_domain_from_record(record)

    {response, state} =
      case :ets.lookup(@hosts_table_name, domain) do
        [{_blocked}] ->
          :logger.info("Blocked #{domain}")
          state = Map.update!(state, :blocked_requests, &(&1 + 1))
          {DNSUtils.make_blocked_dns_response(record), state}

        [] ->
          :logger.info("Allowed #{domain}")
          state = Map.update!(state, :allowed_requests, &(&1 + 1))
          {DNSUtils.forward_real_dns_response(state, packet), state}
      end

    :gen_udp.send(socket, client_ip, port, response)
    {:noreply, state}
  end

  defp load_hosts_into_ets() do
    :ets.delete_all_objects(@hosts_table_name)
    :ets.insert(@hosts_table_name, Expunji.Hosts.parse_all_files())
  end
end
