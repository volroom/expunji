defmodule Expunji.HostsFileReader do
  @moduledoc """
  Hosts file reader for actual use
  """
  @behaviour Expunji.HostsFileReaderBehaviour

  def ls!(path), do: File.ls!(path)
  def stream!(path), do: File.stream!(path)
end
