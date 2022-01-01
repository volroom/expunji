defmodule Expunji.ServerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mox
  require Logger
  alias Expunji.DNS.NameserverClientMock
  alias Expunji.DNS.TestClient
  alias Expunji.HostsFileReaderMock
  alias Expunji.Server

  @allowed_ns_packet <<154, 229, 129, 0, 0, 1, 0, 4, 0, 0, 0, 1, 11, 101, 108, 105, 120, 105, 114,
                       45, 108, 97, 110, 103, 3, 111, 114, 103, 0, 0, 1, 0, 1, 192, 12, 0, 1, 0,
                       1, 0, 0, 1, 44, 0, 4, 185, 199, 108, 153, 192, 12, 0, 1, 0, 1, 0, 0, 1, 44,
                       0, 4, 185, 199, 111, 153, 192, 12, 0, 1, 0, 1, 0, 0, 1, 44, 0, 4, 185, 199,
                       110, 153, 192, 12, 0, 1, 0, 1, 0, 0, 1, 44, 0, 4, 185, 199, 109, 153, 0, 0,
                       41, 4, 208, 0, 0, 0, 0, 0, 0>>
  @invalid_packet <<60, 1, 32, 0, 1, 0, 0, 0, 0, 0, 1, 9, 98, 97, 100, 100, 111, 109, 97, 105,
                    110, 3, 99, 111, 109, 0, 0, 1, 0, 1, 0, 0, 41, 16, 0, 0, 0, 0, 0, 0, 0>>

  setup_all do
    stub(NameserverClientMock, :query, fn _, _ -> :ok end)
    stub(HostsFileReaderMock, :exists?, fn _ -> false end)
    stub(HostsFileReaderMock, :ls!, fn _ -> ["hosts1"] end)
    stub(HostsFileReaderMock, :stream!, fn _ -> ["baddomain.com"] end)
    set_mox_global()
    server_pid = start_supervised!(Server)
    state = Server.get_state()

    %{server_pid: server_pid, state: state}
  end

  describe "dns" do
    @tag capture_log: true
    test "rejects invalid dns packets" do
      assert {:noreply, %{}} =
               Server.handle_info({:udp, nil, {127, 0, 0, 1}, 100, @invalid_packet}, %{})
    end

    test "returns a blocked response for domains in the blocked list" do
      assert TestClient.query_domain('baddomain.com') == :blocked
    end

    test "returns a real response for domains not in the blocked list", context do
      %{state: %{nameserver_socket: nameserver_socket}} = context
      Process.send_after(Server, {:udp, nameserver_socket, :ip, :length, @allowed_ns_packet}, 50)
      assert TestClient.query_domain('elixir-lang.org') == :allowed
      clear_caches()
    end

    test "returns a cached response for domains not in the blocked list that have been served already" do
      request_id = :rand.uniform(1_000)
      {:ok, record} = :inet_dns.decode(@allowed_ns_packet)
      Cachex.put(:dns_cache, {'elixir-lang.org', :a, :in}, record)
      assert TestClient.query_domain('elixir-lang.org', request_id) == :allowed
      clear_caches()
    end

    test "handles abandoned queries", context do
      %{state: %{nameserver_socket: nameserver_socket} = state} = context

      assert capture_log(fn ->
               Server.handle_info(
                 {:udp, nameserver_socket, :ip, :length, @allowed_ns_packet},
                 state
               )
             end) =~ "Abandoned query"

      clear_caches()
    end
  end

  describe "reload_hosts/0" do
    test "reloads hosts files into hosts table" do
      :ets.insert(:hosts_table, [{'baddomain2.com'}])
      Server.reload_hosts()

      Process.sleep(50)

      assert :ets.tab2list(:hosts_table) == [{'baddomain.com'}]
    end
  end

  defp clear_caches do
    Cachex.clear(:dns_cache)
    :ets.delete_all_objects(:active_queries)
  end
end
