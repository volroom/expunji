# Expunji

**DNS Sinkhole made with Elixir**

## Setup
* Install Elixir  - https://elixir-lang.org/install.html
* Download some blocklists, and put them in `hosts/`
* Start server with `iex -S mix`

Done! Now start sending it DNS requests.

All domains present in your hosts files will be answered with 0.0.0.0, all others will be sent real answers from Cloudflare.
