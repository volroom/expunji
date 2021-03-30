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
    default_state = %{
      allowed_requests: 0,
      blocked_requests: 0,
      client_socket: nil,
      nameserver_socket: nil
    }

    GenServer.start_link(__MODULE__, default_state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    :ets.new(:active_queries, [:set, :named_table])
    :ets.new(:hosts_table, [:set, :named_table])

    :logger.info("Opening sockets")
    {:ok, client_socket} = :gen_udp.open(@client_socket_port, [:binary, active: true])
    {:ok, nameserver_socket} = :gen_udp.open(@nameserver_socket_port, [:binary, active: true])
    state = %{state | client_socket: client_socket, nameserver_socket: nameserver_socket}
    :logger.info("Server up")

    {:ok, state, {:continue, :load_hosts}}
  end

  def clear_active_queries() do
    GenServer.call(__MODULE__, :clear_active_queries)
  end

  def get_stats() do
    GenServer.call(__MODULE__, :get_stats)
  end

  def reload_hosts() do
    GenServer.cast(__MODULE__, :reload_hosts)
  end

  @impl true
  def handle_call(:clear_active_queries, _from, state) do
    :ets.delete_all_objects(:active_queries)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    %{allowed_requests: allowed, blocked_requests: blocked} = state
    total = allowed + blocked
    allowed_perc = Float.round(allowed / total * 100, 2)
    blocked_perc = Float.round(blocked / total * 100, 2)

    :logger.info("""
    Allowed: #{allowed_perc}% (#{allowed} requests)
    Blocked: #{blocked_perc}% (#{blocked} requests)
    Total: #{total} requests
    """)

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(
        {:udp, socket, client_ip, port, packet},
        %{client_socket: client_socket, nameserver_socket: nameserver_socket} = state
      )
      when socket == client_socket do
    with {:ok, record} <- :inet_dns.decode(packet),
         {:ok, {domain, _, _} = key} <- DNSUtils.get_key_from_record(record) do
      state =
        case :ets.lookup(:hosts_table, domain) do
          [{_blocked}] ->
            :logger.info("Blocked #{domain}")
            response = DNSUtils.make_blocked_dns_response(record)
            :gen_udp.send(socket, client_ip, port, response)

            Map.update!(state, :blocked_requests, &(&1 + 1))

          [] ->
            request_id = DNSUtils.get_request_id_from_record(record)

            case Cachex.get(:dns_cache, key) do
              {:ok, nil} ->
                :logger.info("Allowed #{domain}")
                :ets.insert(:active_queries, {key, {client_ip, port, request_id}})
                :gen_udp.send(nameserver_socket, @nameserver_ip, @nameserver_dest_port, packet)

              {:ok, cached_response} ->
                :logger.info("Allowed (from cache) #{domain}")
                response = DNSUtils.make_allowed_dns_response(cached_response, request_id, 0)
                :gen_udp.send(socket, client_ip, port, response)
            end

            Map.update!(state, :allowed_requests, &(&1 + 1))
        end

      {:noreply, state}
    else
      _ ->
        :logger.error("Bad query: #{packet}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(
        {:udp, socket, _nameserver_ip, _nameserver_port, packet},
        %{client_socket: client_socket, nameserver_socket: nameserver_socket} = state
      )
      when socket == nameserver_socket do
    with {:ok, record} <- :inet_dns.decode(packet),
         {:ok, {domain, _, _} = key} <- DNSUtils.get_key_from_record(record) do
      ttl = DNSUtils.get_ttl_from_record(record)

      if ttl > 0 do
        Cachex.put(:dns_cache, key, record, ttl: :timer.seconds(ttl))
      end

      case :ets.take(:active_queries, key) do
        [{_, {client_ip, client_port, _request_id}}] ->
          :gen_udp.send(client_socket, client_ip, client_port, packet)

        [] ->
          :logger.info("Abandoned query: #{domain}")
      end

      {:noreply, state}
    else
      _ ->
        :logger.error("Bad nameserver response: #{packet}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:reload_hosts, state) do
    load_hosts_into_ets()

    {:noreply, state}
  end

  @impl true
  def handle_continue(:load_hosts, state) do
    load_hosts_into_ets()

    {:noreply, state}
  end

  defp load_hosts_into_ets() do
    hosts = Expunji.Hosts.parse_all_files()
    :logger.info("Finished loading hosts")

    :ets.delete_all_objects(:hosts_table)
    :ets.insert(:hosts_table, hosts)
  end
end
