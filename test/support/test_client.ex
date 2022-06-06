defmodule Expunji.DNS.TestClient do
  @moduledoc """
  DNS Client for testing
  """

  alias Expunji.DNS.Utils

  def query_domain(domain, request_id \\ nil) do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])
    packet = Utils.make_dns_query(domain, :a, request_id)

    :gen_udp.send(socket, {127, 0, 0, 1}, client_socket_port(), [], packet)
    {:ok, {_ip, _port, response}} = :gen_udp.recv(socket, 0, 100)
    {:ok, decoded_response} = :inet_dns.decode(response)
    Utils.get_query_outcome(decoded_response)
  end

  defp client_socket_port, do: Application.fetch_env!(:expunji, :client_socket_port)
end
