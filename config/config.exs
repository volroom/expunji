import Config

{:ok, blocked_ip} =
  "EXPUNJI_BLOCKED_IP"
  |> System.get_env("0.0.0.0")
  |> String.to_charlist()
  |> :inet.parse_ipv4_address()

{:ok, nameserver_ip} =
  "EXPUNJI_NAMESERVER_IP"
  |> System.get_env("1.1.1.1")
  |> String.to_charlist()
  |> :inet.parse_ipv4_address()

config :expunji,
  blocked_ip: blocked_ip,
  client_socket_port: System.get_env("EXPUNJI_CLIENT_SOCKET_PORT", "53") |> String.to_integer(),
  hosts_dir: System.get_env("EXPUNJI_HOSTS_DIR", "hosts/"),
  hosts_file_reader: Expunji.HostsFileReader,
  nameserver_client: Expunji.DNS.NameserverClient,
  nameserver_dest_port:
    System.get_env("EXPUNJI_NAMESERVER_DEST_PORT", "53") |> String.to_integer(),
  nameserver_ip: nameserver_ip,
  nameserver_socket_port:
    System.get_env("EXPUNJI_NAMESERVER_SOCKET_PORT", "0") |> String.to_integer(),
  whitelist_path: System.get_env("EXPUNJI_WHITELIST_PATH", "whitelist")

config :expunji,
       ExpunjiWeb.Endpoint,
       http: [port: 4000],
       render_errors: [
         view: ExpunjiWeb.ErrorView,
         accepts: ~w(html json),
         layout: false
       ]

log_levels = %{"debug" => :debug, "error" => :error, "info" => :info, "warn" => :warn}
log_level = Map.get(log_levels, System.get_env("EXPUNJI_LOG_LEVEL", "info"))

config :logger, level: log_level
config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
