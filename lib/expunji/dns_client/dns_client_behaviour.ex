defmodule Expunji.DNSClientBehaviour do
  @moduledoc """
  Behaviour for modules that send DNS queries to nameservers & clients
  """

  @callback query_nameserver(binary(), port()) :: :ok | {:error, String.t()}
  @callback respond_to_client(binary(), port(), tuple(), integer()) :: :ok | {:error, String.t()}
end
