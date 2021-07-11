defmodule Expunji.Server do
  @moduledoc """
  Main server.
  Loads hosts files into ETS on startup.
  Accepts DNS requests and blocks them or passes through to real DNS server based on loaded hosts files.
  """

  use GenServer

  alias Expunji.DNSUtils

  @client_socket_port Application.compile_env!(:expunji, :client_socket_port)
  @nameserver_dest_port Application.compile_env!(:expunji, :nameserver_dest_port)
  @nameserver_ip Application.compile_env!(:expunji, :nameserver_ip)
  @nameserver_socket_port Application.compile_env!(:expunji, :nameserver_socket_port)

  def start_link(_) do
    GenServer.start_link(__MODULE__, default_state(), name: __MODULE__)
  end

  @impl true
  def init(state) do
    :ets.new(:active_queries, [:set, :named_table])
    :ets.new(:hosts_table, [:set, :named_table, :public, read_concurrency: true])

    :logger.info("Opening sockets")
    {:ok, client_socket} = :gen_udp.open(@client_socket_port, [:binary, active: true])
    {:ok, nameserver_socket} = :gen_udp.open(@nameserver_socket_port, [:binary, active: true])
    state = %{state | client_socket: client_socket, nameserver_socket: nameserver_socket}
    :logger.info("Server up")

    {:ok, state, {:continue, :load_hosts}}
  end

  def default_state do
    %{
      abandoned: 0,
      allowed: 0,
      blocked: 0,
      client_socket: nil,
      nameserver_socket: nil
    }
  end

  def get_state(), do: GenServer.call(__MODULE__, :get_state)

  def reload_hosts() do
    GenServer.cast(__MODULE__, :reload_hosts)
  end

  @impl GenServer
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl GenServer
  def handle_cast(:reload_hosts, state) do
    load_hosts_into_ets()

    {:noreply, state}
  end

  @impl GenServer
  def handle_continue(:load_hosts, state) do
    load_hosts_into_ets()

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:udp, socket, _, _, packet} = message, state) do
    with {:ok, record} <- :inet_dns.decode(packet),
         {:ok, {domain, _, _} = key} <- DNSUtils.get_key_from_record(record) do
      state =
        if socket == state.client_socket do
          case :ets.lookup(:hosts_table, domain) do
            [{_blocked}] -> send_blocked_response(state, message, record, domain)
            [] -> allow_request(state, message, record, domain, key)
          end
        else
          send_allowed_response(state, message, record, domain, key)
        end

      {:noreply, state}
    else
      _ ->
        :logger.error("Bad packet: #{packet}")
        {:noreply, state}
    end
  end

  def load_hosts_into_ets() do
    hosts = Expunji.Hosts.parse_all_files()
    :logger.info("Finished loading hosts")

    :ets.delete_all_objects(:hosts_table)
    :ets.insert(:hosts_table, hosts)
  end

  def allow_request(state, {:udp, client_socket, ip, port, packet}, record, domain, key) do
    request_id = DNSUtils.get_request_id_from_record(record)

    case Cachex.get(:dns_cache, key) do
      {:ok, nil} ->
        :ets.insert(:active_queries, {key, {ip, port, request_id}})
        :gen_udp.send(state.nameserver_socket, @nameserver_ip, @nameserver_dest_port, packet)
        state

      {:ok, cached_response} ->
        :logger.info("Allowed (from cache) #{domain}")
        response = DNSUtils.make_allowed_dns_response(cached_response, request_id, 0)
        :gen_udp.send(client_socket, ip, port, response)
        Map.update!(state, :allowed, &(&1 + 1))
    end
  end

  def send_allowed_response(state, {:udp, _nameserver_socket, _, _, packet}, record, domain, key) do
    ttl = DNSUtils.get_ttl_from_record(record)

    if ttl > 0 do
      Cachex.put(:dns_cache, key, record, ttl: :timer.seconds(ttl))
    end

    case :ets.take(:active_queries, key) do
      [{_, {ip, port, _request_id}}] ->
        :logger.info("Allowed #{domain}")
        :gen_udp.send(state.client_socket, ip, port, packet)
        Map.update!(state, :allowed, &(&1 + 1))

      [] ->
        :logger.error("Abandoned query: #{domain}")
        Map.update!(state, :abandoned, &(&1 + 1))
    end
  end

  def send_blocked_response(state, {:udp, client_socket, ip, port, _}, record, domain) do
    :logger.info("Blocked #{domain}")
    response = DNSUtils.make_blocked_dns_response(record)
    :gen_udp.send(client_socket, ip, port, response)

    Map.update!(state, :blocked, &(&1 + 1))
  end
end
