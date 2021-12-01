use Mix.Config

config :expunji,
  dns_client: Expunji.DNSClientMock,
  env: :test,
  hosts_file_reader: Expunji.HostsFileReaderMock

config :logger, level: :warn
