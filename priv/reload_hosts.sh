#!/bin/sh
# Example shell script to automate hosts file updates
# Add some commands to update your hosts files here
# Then update Expunji
./home/pi/expunji/_build/dev/rel/expunji/bin/expunji rpc "Expunji.Server.reload_hosts()"
