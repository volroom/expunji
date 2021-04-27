defmodule Expunji.Hosts do
  @moduledoc """
  Functions to parse hosts files
  """

  @hosts_dir Application.compile_env!(:expunji, :hosts_dir)
  @file_module Application.compile_env!(:expunji, :file_module)

  def parse_all_files() do
    :logger.info("Loading hosts files...")

    hosts =
      @hosts_dir
      |> @file_module.ls!()
      |> Enum.filter(&(&1 != ".gitignore"))
      |> Enum.flat_map(fn filename ->
        parse_file(Path.join(@hosts_dir, filename))
      end)

    hosts
  end

  def parse_file(filename) do
    :logger.info(filename)

    filename
    |> @file_module.stream!()
    |> Enum.flat_map(&parse_line(&1))
  end

  def parse_line(line) do
    words = String.split(line)
    first_word = List.first(words)

    if first_word != nil and String.first(first_word) != "#" do
      domain =
        case words do
          [_ip | [domain | _]] ->
            domain

          [domain] ->
            domain
        end

      [{String.to_charlist(domain)}]
    else
      []
    end
  end
end
