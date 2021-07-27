use Mix.Config

config :expunji,
  children: [{Cachex, name: :dns_cache}],
  dns_client: Expunji.DNSClientMock,
  hosts_file_reader: Expunji.HostsFileReaderMock

config :logger, level: :warn
