defmodule Expunji.DNSClient do
  @moduledoc """
  Client for sending DNS requests to a nameserver
  """
  @behaviour Expunji.DNSClientBehaviour

  @nameserver_dest_port Application.compile_env!(:expunji, :nameserver_dest_port)
  @nameserver_ip Application.compile_env!(:expunji, :nameserver_ip)

  def query_nameserver(packet, socket) do
    :gen_udp.send(socket, @nameserver_ip, @nameserver_dest_port, packet)
  end

  def respond_to_client(packet, socket, ip, port) do
    :gen_udp.send(socket, ip, port, packet)
  end
end
