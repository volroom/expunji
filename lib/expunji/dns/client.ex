defmodule Expunji.DNS.Client do
  @moduledoc """
  Client for sending DNS requests to a nameserver
  """

  def respond_to_client(packet, socket, ip, port) do
    :gen_udp.send(socket, ip, port, packet)
  end
end
