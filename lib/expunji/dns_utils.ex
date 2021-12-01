defmodule Expunji.DNSUtils do
  @moduledoc """
  Functions to parse DNS traffic
  """

  @blocked_ip Application.compile_env!(:expunji, :blocked_ip)

  def get_key_from_record({:dns_rec, _, [{:dns_query, domain, type, class, _}], _, _, _}) do
    {:ok, {domain, type, class}}
  end

  def get_key_from_record(_), do: {:error, "INVALID_RECORD"}

  def get_request_id_from_record({:dns_rec, request_header, _, _, _, _}) do
    {:dns_header, id, _, _, _, _, _, _, _, _} = request_header

    id
  end

  def get_ttl_from_record({:dns_rec, _, _, anlist, _, _}) do
    case anlist do
      [{:dns_rr, _, _, _, _, ttl, _, _, _, _} | _] ->
        ttl

      [] ->
        default_ttl()
    end
  end

  def make_blocked_dns_response({:dns_rec, request_header, [query], _, _, _} = record) do
    {:dns_query, domain, _type, class, _unicast} = query

    header = make_response_header(request_header)
    anlist = [{:dns_rr, domain, :a, class, 0, blocked_ttl(), @blocked_ip, nil, [], false}]

    make_response_from_record(record, header, anlist)
  end

  def make_allowed_dns_response(record, request_id, authoritative) do
    {:dns_rec, request_header, _, anlist, _, _} = record
    header = make_response_header(request_header, request_id, authoritative)

    make_response_from_record(record, header, anlist)
  end

  def make_response_header(request_header, request_id \\ nil, authoritative \\ 1) do
    {:dns_header, id, _, opcode, _, _, rd, _, pr, rcode} = request_header

    {:dns_header, request_id || id, 1, opcode, authoritative, 0, rd, 0, pr, rcode}
  end

  def make_dns_query(domain, type) do
    request_id = :rand.uniform(1_000)

    {
      :dns_rec,
      {:dns_header, request_id, false, :query, false, false, true, false, false, 0},
      [{:dns_query, domain, type, :in, false}],
      [],
      [],
      [{:dns_rr_opt, '.', :opt, 4_096, 0, 0, 0, ""}]
    }
    |> :inet_dns.encode()
  end

  def get_query_outcome({:dns_rec, _, _, [{:dns_rr, _, _, _, _, _, @blocked_ip, _, _, _}], _, _}) do
    :blocked
  end

  def get_query_outcome({:dns_rec, _, _, [{:dns_rr, _, _, _, _, _, _result, _, _, _}], _, _}) do
    :allowed
  end

  def blocked_ttl, do: 2
  def default_ttl, do: 300

  defp make_response_from_record({:dns_rec, _, qdlist, _, nslist, arlist}, header, anlist) do
    :inet_dns.encode({:dns_rec, header, qdlist, anlist, nslist, arlist})
  end
end
