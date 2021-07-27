defmodule Expunji.ServerTest do
  use ExUnit.Case

  alias Expunji.DNSClientMock
  alias Expunji.HostsFileReaderMock
  alias Expunji.Server

  @allowed_packet <<160, 94, 1, 32, 0, 1, 0, 0, 0, 0, 0, 1, 11, 101, 108, 105, 120, 105, 114, 45,
                    108, 97, 110, 103, 3, 111, 114, 103, 0, 0, 1, 0, 1, 0, 0, 41, 16, 0, 0, 0, 0,
                    0, 0, 0>>
  @allowed_ns_packet <<60, 232, 129, 128, 0, 1, 0, 4, 0, 0, 0, 1, 11, 101, 108, 105, 120, 105,
                       114, 45, 108, 97, 110, 103, 3, 111, 114, 103, 0, 0, 1, 0, 1, 192, 12, 0, 1,
                       0, 1, 0, 0, 1, 8, 0, 4, 185, 199, 110, 153, 192, 12, 0, 1, 0, 1, 0, 0, 1,
                       8, 0, 4, 185, 199, 109, 153, 192, 12, 0, 1, 0, 1, 0, 0, 1, 8, 0, 4, 185,
                       199, 111, 153, 192, 12, 0, 1, 0, 1, 0, 0, 1, 8, 0, 4, 185, 199, 108, 153,
                       0, 0, 41, 4, 208, 0, 0, 0, 0, 0, 0>>
  @blocked_packet <<58, 60, 1, 32, 0, 1, 0, 0, 0, 0, 0, 1, 9, 98, 97, 100, 100, 111, 109, 97, 105,
                    110, 3, 99, 111, 109, 0, 0, 1, 0, 1, 0, 0, 41, 16, 0, 0, 0, 0, 0, 0, 0>>
  @invalid_packet <<60, 1, 32, 0, 1, 0, 0, 0, 0, 0, 1, 9, 98, 97, 100, 100, 111, 109, 97, 105,
                    110, 3, 99, 111, 109, 0, 0, 1, 0, 1, 0, 0, 41, 16, 0, 0, 0, 0, 0, 0, 0>>

  setup_all do
    Mox.stub(DNSClientMock, :query_nameserver, fn _, _ -> :ok end)
    Mox.stub(DNSClientMock, :respond_to_client, fn _, _, _, _ -> :ok end)
    Mox.stub(HostsFileReaderMock, :ls!, fn _ -> ["hosts1"] end)
    Mox.stub(HostsFileReaderMock, :stream!, fn _ -> ["baddomain.com"] end)
    Mox.set_mox_global()
    server_pid = start_supervised!(Server)

    %{server_pid: server_pid}
  end

  describe "dns" do
    @tag capture_log: true
    test "rejects invalid dns packets" do
      %{client_socket: client_socket} = state = Server.get_state()

      assert {:noreply, ^state} =
               Server.handle_info(
                 {:udp, client_socket, {127, 0, 0, 1}, 100, @invalid_packet},
                 state
               )
    end

    test "returns a blocked response for domains in the blocked list" do
      %{client_socket: client_socket} = state = Server.get_state()

      {:noreply, new_state} =
        Server.handle_info({:udp, client_socket, {127, 0, 0, 1}, 100, @blocked_packet}, state)

      assert new_state.blocked == state.blocked + 1
    end

    test "returns a real response for domains not in the blocked list" do
      %{client_socket: client_socket, nameserver_socket: nameserver_socket} =
        state = Server.get_state()

      {:noreply, state} =
        Server.handle_info({:udp, client_socket, {127, 0, 0, 1}, 100, @allowed_packet}, state)

      {:noreply, new_state} =
        Server.handle_info(
          {:udp, nameserver_socket, {8, 8, 8, 8}, 100, @allowed_ns_packet},
          state
        )

      assert new_state.allowed == state.allowed + 1
      clear_caches()
    end

    test "returns a cached response for domains not in the blocked list that have been served already" do
      %{client_socket: client_socket, nameserver_socket: nameserver_socket} =
        old_state = Server.get_state()

      {:noreply, state} =
        Server.handle_info({:udp, client_socket, {127, 0, 0, 1}, 100, @allowed_packet}, old_state)

      {:noreply, state} =
        Server.handle_info(
          {:udp, nameserver_socket, {8, 8, 8, 8}, 100, @allowed_ns_packet},
          state
        )

      {:noreply, new_state} =
        Server.handle_info({:udp, client_socket, {127, 0, 0, 1}, 100, @allowed_packet}, state)

      assert new_state.allowed == old_state.allowed + 2
      assert new_state.cache_hits == old_state.cache_hits + 1
      clear_caches()
    end

    @tag capture_log: true
    test "handles abandoned queries" do
      %{nameserver_socket: nameserver_socket} = state = Server.get_state()

      {:noreply, new_state} =
        Server.handle_info(
          {:udp, nameserver_socket, {8, 8, 8, 8}, 100, @allowed_ns_packet},
          state
        )

      assert new_state.abandoned == state.abandoned + 1
      clear_caches()
    end
  end

  describe "get_state/0" do
    test "can get state" do
      state = Server.get_state()
      stats_keys = [:abandoned, :allowed, :blocked, :cache_hits]

      assert Map.take(state, stats_keys) == Map.take(Server.default_state(), stats_keys)
      assert is_port(state.client_socket)
      assert is_port(state.nameserver_socket)
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
