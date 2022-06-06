defmodule Expunji.DNS.NameserverClient do
  @moduledoc """
  Sends queries to nameserver
  """
  @behaviour Expunji.DNS.NameserverClientBehaviour

  def query(packet, socket) do
    :gen_udp.send(socket, nameserver_ip(), nameserver_dest_port(), packet)
  end

  defp nameserver_dest_port, do: Application.fetch_env!(:expunji, :nameserver_dest_port)
  defp nameserver_ip, do: Application.fetch_env!(:expunji, :nameserver_ip)
end
