import Config

{:ok, blocked_ip} =
  "EXPUNJI_BLOCKED_IP"
  |> System.get_env("1.1.1.1")
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
    System.get_env("EXPUNJI_NAMESERVER_SOCKET_PORT", "51234") |> String.to_integer()
