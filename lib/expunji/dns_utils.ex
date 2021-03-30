defmodule Expunji.DNSUtils do
  @moduledoc """
  Functions to parse DNS traffic
  """

  @blocked_ip Application.compile_env!(:expunji, :blocked_ip)
  @blocked_ttl 2
  @domain_not_found_ttl 5 * 60

  def get_key_from_record({:dns_rec, _, [{:dns_query, domain, type, class}], _, _, _}) do
    {:ok, {domain, type, class}}
  end

  def get_key_from_record(_), do: {:error, "INVALID_RECORD"}

  def get_request_id_from_record(record) do
    {:dns_rec, request_header, _, _, _, _} = record
    {:dns_header, id, _, _, _, _, _, _, _, _} = request_header

    id
  end

  def get_ttl_from_record({:dns_rec, _, _, anlist, _, _}) do
    case anlist do
      [{:dns_rr, _, _, _, _, ttl, _, _, _, _} | _] ->
        ttl

      [] ->
        @domain_not_found_ttl
    end
  end

  def make_blocked_dns_response(record) do
    {:dns_rec, request_header, [query], _, _, _} = record
    {:dns_query, domain, _type, class} = query

    header = make_response_header(request_header)
    anlist = [{:dns_rr, domain, :a, class, 0, @blocked_ttl, @blocked_ip, nil, [], false}]

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

  defp make_response_from_record(record, header, anlist) do
    {:dns_rec, _, qdlist, _, nslist, arlist} = record

    :inet_dns.encode({:dns_rec, header, qdlist, anlist, nslist, arlist})
  end
end
