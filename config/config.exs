import Config

config :expunji,
  hosts_file_reader: Expunji.HostsFileReader,
  nameserver_client: Expunji.DNS.NameserverClient

config :expunji,
       ExpunjiWeb.Endpoint,
       render_errors: [
         view: ExpunjiWeb.ErrorView,
         accepts: ~w(html json),
         layout: false
       ],
       server: true

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
