defmodule Expunji.HostsTest do
  use ExUnit.Case, async: true

  alias Expunji.Hosts

  describe "parse_file/1" do
    assert Hosts.parse_file("hosts") == [[], [], [{'baddomain.com'}], [{'baddomain.org'}]]
  end

  describe "parse_line/1" do
    test "skips blank lines" do
      assert Hosts.parse_line(" ") == []
    end

    test "skips comments" do
      assert Hosts.parse_line("# a comment") == []
    end

    test "uses 2nd word if >2 words present" do
      assert Hosts.parse_line("127.0.0.1 hostname.com 098123") == [{'hostname.com'}]
    end

    test "uses 2nd word if 2 words present" do
      assert Hosts.parse_line("127.0.0.1 hostname.com") == [{'hostname.com'}]
    end

    test "uses 1st word if only 1 word present" do
      assert Hosts.parse_line("hostname.com") == [{'hostname.com'}]
    end
  end
end
