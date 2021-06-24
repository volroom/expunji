defmodule Expunji.HostsTest do
  use ExUnit.Case, async: true
  import Mox

  alias Expunji.Hosts
  alias Expunji.HostsFileReaderMock

  setup :verify_on_exit!

  describe "parse_file/1" do
    test "loads a file and parses each line" do
      file_lines = ["# Comment", "", "127.0.0.1 baddomain.com", "127.0.0.1 baddomain.org"]
      expect(HostsFileReaderMock, :stream!, fn "hosts" -> file_lines end)
      expected_result = [{'baddomain.com'}, {'baddomain.org'}]

      assert Hosts.parse_file("hosts") == expected_result
    end
  end

  describe "parse_line/1" do
    test "skips blank lines" do
      assert Hosts.parse_line(" ") == []
      assert Hosts.parse_line("") == []
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
