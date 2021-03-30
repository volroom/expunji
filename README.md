# Expunji

**DNS Sinkhole made with Elixir**

## Setup
* Install Elixir - https://elixir-lang.org/install.html
* Install dependencies - `mix deps.get`
* Download some blocklists, and put them in `hosts/`
* Start server with `iex -S mix`

Done! Now start sending it DNS requests.

All domains present in your hosts files will be answered with 0.0.0.0, all others will be sent real answers.

## Configuration
The following environment variables may be used to configure Expunji:
```
EXPUNJI_BLOCKED_IP - IP address to answer blocked domains with (default 0.0.0.0)
EXPUNJI_CLIENT_SOCKET_PORT - Port number to listen for DNS requests on (default 53)
EXPUNJI_HOSTS_DIR - Directory where hosts files are located (default "hosts/")
EXPUNJI_NAMESERVER_IP - The IP address of the nameserver to forward requests to (default 1.1.1.1)
EXPUNJI_NAMESERVER_DEST_PORT - Port number to forward requests to on nameserver (default 53)
EXPUNJI_NAMESERVER_SOCKET_PORT - Port number to send forwarded requests from (default 0 - i.e. random available port)
```
