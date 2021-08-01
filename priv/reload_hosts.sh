#!/usr/bin/bash
# Example shell script to automate hosts file updates
# Add some commands to update your hosts files here
# Then update Expunji
cd /home/pi/expunji/_build/prod/rel/expunji/bin
./expunji rpc "Expunji.Server.reload_hosts()"
