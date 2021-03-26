defmodule Expunji.DNSUtils do
  @moduledoc """
  Functions to parse DNS traffic
  """

  @blocked_ip Application.fetch_env!(:expunji, :blocked_ip)
  @nameserver_dest_port Application.fetch_env!(:expunji, :nameserver_dest_port)
  @nameserver_ip Application.fetch_env!(:expunji, :nameserver_ip)

  def decode(packet) do
    {:ok, record} = :inet_dns.decode(packet)
    record
  end

  def get_domain_from_record({:dns_rec, _, [query], _, _, _}), do: get_domain_from_query(query)

  def get_domain_from_query({:dns_query, domain, _, _}), do: domain
  def get_type_from_query({:dns_query, _, type, _}), do: type

  def make_blocked_dns_response(record) do
    {:dns_rec, request_header, [query], _, _, _} = record
    domain = get_domain_from_query(query)
    type = get_type_from_query(query)

    header = make_response_header(request_header)
    anlist = [{:dns_rr, domain, type, :in, 0, 2, @blocked_ip, nil, [], false}]
    make_response_from_record(record, header, anlist)
  end

  def make_response_header(request_header) do
    {:dns_header, id, _, opcode, _, _, rd, _, pr, rcode} = request_header

    {:dns_header, id, 1, opcode, 1, 0, rd, 0, pr, rcode}
  end

  defp make_response_from_record(record, header, anlist) do
    {:dns_rec, _, qdlist, _, nslist, arlist} = record

    :inet_dns.encode({:dns_rec, header, qdlist, anlist, nslist, arlist})
  end

  def forward_real_dns_response(%{nameserver_socket: socket}, packet) do
    :gen_udp.send(socket, @nameserver_ip, @nameserver_dest_port, packet)
    {:ok, {_ip, _port, response}} = :gen_udp.recv(socket, 0)
    response
  end
end
