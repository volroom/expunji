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
  nameserver_dest_port:
    System.get_env("EXPUNJI_NAMESERVER_DEST_PORT", "53") |> String.to_integer(),
  nameserver_ip: nameserver_ip,
  nameserver_socket_port:
    System.get_env("EXPUNJI_NAMESERVER_SOCKET_PORT", "0") |> String.to_integer(),
  whitelist_path: System.get_env("EXPUNJI_WHITELIST_PATH", "whitelist")

config :expunji,
       ExpunjiWeb.Endpoint,
       http: [port: System.get_env("EXPUNJI_HTTP_PORT", "4000") |> String.to_integer()],
       render_errors: [
         view: ExpunjiWeb.ErrorView,
         accepts: ~w(html json),
         layout: false
       ],
       server: true

log_levels = %{"debug" => :debug, "error" => :error, "info" => :info, "warn" => :warn}

log_level =
  if config_env() == :test do
    :warn
  else
    Map.get(log_levels, System.get_env("EXPUNJI_LOG_LEVEL", "info"))
  end

config :logger, level: log_level
