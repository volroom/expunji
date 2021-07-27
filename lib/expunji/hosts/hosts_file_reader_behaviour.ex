defmodule Expunji.HostsFileReaderBehaviour do
  @moduledoc """
  Behaviour for modules that find and read hosts files
  """

  @callback ls!(Path.t()) :: [binary()]
  @callback stream!(Path.t()) :: File.Stream.t()
end
