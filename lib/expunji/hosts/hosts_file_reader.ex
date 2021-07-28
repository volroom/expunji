defmodule Expunji.HostsFileReader do
  @moduledoc """
  Hosts file reader for actual use
  """
  @behaviour Expunji.HostsFileReaderBehaviour

  def exists?(path), do: File.exists?(path)
  def ls!(path), do: File.ls!(path)
  def stream!(path), do: File.stream!(path)
end
