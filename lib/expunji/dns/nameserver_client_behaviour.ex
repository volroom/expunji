defmodule Expunji.DNS.NameserverClientBehaviour do
  @moduledoc """
  Behaviour for nameserver client
  """

  @callback query(binary(), port()) :: :ok | {:error, String.t()}
end
