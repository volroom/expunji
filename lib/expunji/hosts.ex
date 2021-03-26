defmodule Expunji.Hosts do
  @moduledoc """
  Functions to parse hosts files
  """

  @hosts_dir Application.fetch_env!(:expunji, :hosts_dir)

  def parse_all_files() do
    :logger.info("Loading hosts files...")

    hosts =
      @hosts_dir
      |> File.ls!()
      |> Enum.flat_map(fn filename ->
        parse_file(Path.join(@hosts_dir, filename))
      end)

    hosts
  end

  def parse_file(filename) do
    :logger.info(filename)

    filename
    |> File.stream!()
    |> Enum.flat_map(&parse_line(&1))
  end

  def parse_line(line) do
    words = String.split(line)
    first_word = List.first(words)

    if first_word != nil and String.first(first_word) != "#" do
      [_ip | [domain | _]] = words
      [{String.to_charlist(domain)}]
    else
      []
    end
  end
end
