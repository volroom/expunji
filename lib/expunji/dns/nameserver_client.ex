defmodule Expunji.DNS.NameserverClient do
  @moduledoc """
  Sends queries to nameserver
  """
  @behaviour Expunji.DNS.NameserverClientBehaviour

  @nameserver_dest_port Application.compile_env!(:expunji, :nameserver_dest_port)
  @nameserver_ip Application.compile_env!(:expunji, :nameserver_ip)

  def query(packet, socket) do
    :gen_udp.send(socket, @nameserver_ip, @nameserver_dest_port, packet)
  end
end
