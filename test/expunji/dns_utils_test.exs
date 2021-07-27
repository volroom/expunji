defmodule Expunji.DNSUtilsTest do
  use ExUnit.Case, async: true

  alias Expunji.DNSUtils

  @valid_record {:dns_rec,
                 {:dns_header, 23_017, false, :query, false, false, true, false, false, 0},
                 [{:dns_query, 'elixir-lang.org', :a, :in}], [], [],
                 [{:dns_rr_opt, '.', :opt, 4_096, 0, 0, 0, ""}]}
  @invalid_record {:dns_rec,
                   {:dns_header, 23_017, false, :query, false, false, true, false, false, 0},
                   [{:dns_query, 'elixir-lang.org', :a}], [], [],
                   [{:dns_rr_opt, '.', :opt, 4_096, 0, 0, 0, ""}]}
  @answer_record {:dns_rec, {:dns_header, 200, true, :query, false, false, true, true, false, 0},
                  [{:dns_query, 'elixir-lang.org', :a, :in}],
                  [
                    {:dns_rr, 'elixir-lang.org', :a, :in, 0, 200, {185, 199, 109, 153},
                     :undefined, [], false},
                    {:dns_rr, 'elixir-lang.org', :a, :in, 0, 200, {185, 199, 108, 153},
                     :undefined, [], false},
                    {:dns_rr, 'elixir-lang.org', :a, :in, 0, 200, {185, 199, 110, 153},
                     :undefined, [], false},
                    {:dns_rr, 'elixir-lang.org', :a, :in, 0, 200, {185, 199, 111, 153},
                     :undefined, [], false}
                  ], [], [{:dns_rr_opt, '.', :opt, 1_232, 0, 0, 0, ""}]}
  @allowed_answer_record {:dns_rec,
                          {:dns_header, 23_017, true, :query, false, false, true, false, false,
                           0}, [{:dns_query, 'elixir-lang.org', :a, :in}],
                          [
                            {:dns_rr, 'elixir-lang.org', :a, :in, 0, 200, {185, 199, 109, 153},
                             :undefined, [], false},
                            {:dns_rr, 'elixir-lang.org', :a, :in, 0, 200, {185, 199, 108, 153},
                             :undefined, [], false},
                            {:dns_rr, 'elixir-lang.org', :a, :in, 0, 200, {185, 199, 110, 153},
                             :undefined, [], false},
                            {:dns_rr, 'elixir-lang.org', :a, :in, 0, 200, {185, 199, 111, 153},
                             :undefined, [], false}
                          ], [], [{:dns_rr_opt, '.', :opt, 1_232, 0, 0, 0, ""}]}
  @nonexistent_answer_record {:dns_rec,
                              {:dns_header, 5_337, true, :query, false, false, true, true, false,
                               3}, [{:dns_query, 'noexist.org', :a, :in}], [],
                              [
                                {:dns_rr, 'org', :soa, :in, 0, 900,
                                 {'a0.org.afilias-nst.info', 'noc.afilias-nst.info',
                                  2_014_408_806, 1_800, 900, 604_800, 86_400}, :undefined, [],
                                 false}
                              ], [{:dns_rr_opt, '.', :opt, 1_232, 0, 0, 0, ""}]}

  describe "get_key_from_record/1" do
    test "can get ets table key from record" do
      assert DNSUtils.get_key_from_record(@valid_record) == {:ok, {'elixir-lang.org', :a, :in}}
    end

    test "returns error for invalid record" do
      assert DNSUtils.get_key_from_record(@invalid_record) == {:error, "INVALID_RECORD"}
    end
  end

  describe "get_request_id_from_record/1" do
    test "can get request id from record" do
      assert DNSUtils.get_request_id_from_record(@valid_record) == 23_017
    end
  end

  describe "get_ttl_from_record/1" do
    test "can get answer ttl from record" do
      assert DNSUtils.get_ttl_from_record(@answer_record) == 200
    end

    test "falls back to default ttl if none found in record" do
      assert DNSUtils.get_ttl_from_record(@nonexistent_answer_record) == DNSUtils.default_ttl()
    end
  end

  describe "make_blocked_dns_response/1" do
    test "can make a blocked dns response to a query for a blocked site" do
      {:ok, blocked_response} =
        @answer_record
        |> DNSUtils.make_blocked_dns_response()
        |> :inet_dns.decode()

      assert DNSUtils.get_ttl_from_record(blocked_response) == DNSUtils.blocked_ttl()
    end
  end

  describe "make_allowed_dns_response/3" do
    test "can make an allowed dns response to a query for a blocked site" do
      request_id = DNSUtils.get_request_id_from_record(@valid_record)

      {:ok, allowed_response} =
        @answer_record
        |> DNSUtils.make_allowed_dns_response(request_id, 0)
        |> :inet_dns.decode()

      assert allowed_response == @allowed_answer_record
    end
  end

  describe "make_response_header/3" do
    test "can make a response header to be used when creating records" do
      header = {:dns_header, 23_017, false, :query, false, false, true, false, false, 0}

      assert DNSUtils.make_response_header(header, 2_000) ==
               {:dns_header, 2_000, 1, :query, 1, 0, true, 0, false, 0}
    end
  end
end
