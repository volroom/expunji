ExUnit.start()

Mox.defmock(Expunji.HostsFileReaderMock, for: Expunji.HostsFileReaderBehaviour)

Application.put_env(:expunji, :hosts_file_reader, Expunji.HostsFileReaderMock)
