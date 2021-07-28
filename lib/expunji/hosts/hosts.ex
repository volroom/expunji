defmodule Expunji.Hosts do
  @moduledoc """
  Functions to parse hosts files
  """

  @hosts_dir Application.compile_env!(:expunji, :hosts_dir)
  @hosts_file_reader Application.compile_env!(:expunji, :hosts_file_reader)
  @whitelist_path Application.compile_env!(:expunji, :whitelist_path)

  def parse_all_files() do
    :logger.info("Loading hosts files...")

    @hosts_dir
    |> @hosts_file_reader.ls!()
    |> Enum.filter(&(&1 != ".gitignore"))
    |> Enum.flat_map(fn filename ->
      parse_file(Path.join(@hosts_dir, filename))
    end)
    |> apply_whitelist()
  end

  def apply_whitelist(hosts) do
    if @hosts_file_reader.exists?(@whitelist_path) do
      hosts -- parse_file(@whitelist_path)
    else
      hosts
    end
  end

  def parse_file(filename) do
    :logger.info(filename)

    filename
    |> @hosts_file_reader.stream!()
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
