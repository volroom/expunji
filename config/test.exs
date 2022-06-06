import Config

config :expunji,
  env: :test,
  hosts_file_reader: Expunji.HostsFileReaderMock,
  nameserver_client: Expunji.DNS.NameserverClientMock
