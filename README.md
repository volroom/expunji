# Expunji

**DNS Sinkhole made with Elixir**

## Setup
* Install Elixir - https://elixir-lang.org/install.html
* Install dependencies - `mix deps.get`
* Download some [blocklists](https://github.com/topics/blocklist), and copy/symlink them to `hosts/`
* Start server with `iex -S mix phx.server` or build with `MIX_ENV=prod mix release` (you may need to manually grant
permissions to listen on port 53 depending on your operating system)
* An example SystemD service is included at `priv/expunji.service`

Done! Now start sending it DNS requests.

All domains present in your hosts files will be answered with 0.0.0.0, all others will be sent real answers.

Metrics are made available by a Prometheus endpoint, the default address is:
[http://localhost:4000/metrics](http://localhost:4000/metrics). An example Grafana dashboard is included at
`priv/dashboard.json` and an example Prometheus config is included at `priv/prometheus.yml`.

## Configuration
The following environment variables may be used to configure Expunji:
```
EXPUNJI_BLOCKED_IP - IP address to answer blocked domains with (default 0.0.0.0)
EXPUNJI_CLIENT_SOCKET_PORT - Port number to listen for DNS requests on (default 53)
EXPUNJI_HOSTS_DIR - Directory where hosts files are located (default "hosts/")
EXPUNJI_HTTP_PORT - Port number for the prometheus endpoint (default 4000)
EXPUNJI_LOG_LEVEL - Log level - info/error/debug/warn (default "info"). Set to "error" if you want to hide loglines for
successful DNS queries.
EXPUNJI_NAMESERVER_IP - The IP address of the nameserver to forward requests to (default 1.1.1.1)
EXPUNJI_NAMESERVER_DEST_PORT - Port number to forward requests to on nameserver (default 53)
EXPUNJI_NAMESERVER_SOCKET_PORT - Port number to send forwarded requests from (default 0 - i.e. random available port)
EXPUNJI_WHITELIST_PATH - Path of whitelist file (defaults to a file called "whitelist" in project root)
```

## Whitelist
To make automatic updates of hosts files easier, a whitelist can be used to exclude certain domains.
Add the domains you'd like to whitelist to a file and make it available to Expunji.

## Maintenance
To reload hosts files, run `Expunji.Server.reload_hosts()`
An example shell script that can be used to auto-update hosts is included at `priv/reload_hosts.sh`

## Other Tasks
* Format: `mix format`
* Lint: `mix credo`
* Run Tests: `mix test`
* Get Coverage: `mix coveralls`
