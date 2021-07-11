defmodule Expunji.ServerTest do
  use ExUnit.Case
  import Mox

  alias Expunji.Server
  alias Expunji.HostsFileReaderMock

  setup :set_mox_global

  describe "dns" do
    test "returns a blocked response for domains in the blocked list" do
      :ets.insert(:hosts_table, [{'baddomain.com'}])
    end

    test "returns a real response for domains not in the blocked list" do
    end

    test "returns a cached response for domains not in the blocked list that have been served already" do
    end
  end

  describe "get_state/0" do
    test "can get state", context do
      {:ok, server_pid} = Server.start_link(nil)
      expect(HostsFileReaderMock, :ls!, fn _ -> ["hosts1"] end)
      expect(HostsFileReaderMock, :stream!, fn _ -> [""] end)
      allow(HostsFileReaderMock, self(), server_pid)


      assert Server.default_state() == Server.get_state()
    end
  end
end
