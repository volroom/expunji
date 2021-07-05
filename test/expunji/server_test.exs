defmodule Expunji.ServerTest do
  use ExUnit.Case, async: true

  alias Expunji.Server

  setup :start_server

  describe "dns" do
    test "returns a blocked response for domains in the blocked list" do
      :ets.insert(:hosts_table, [{'baddomain.com'}])
    end

    test "returns a real response for domains not in the blocked list" do
    end

    test "returns a cached response for domains not in the blocked list that have been served already" do
    end
  end

  defp start_server(_) do
    {:ok, server_pid} = Server.start_link(nil)
    [server_pid: server_pid]
  end
end
