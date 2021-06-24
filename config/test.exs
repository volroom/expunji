use Mix.Config

config :expunji,
  children: [],
  hosts_file_reader: Expunji.HostsFileReaderMock
