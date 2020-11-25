#!/bin/bash

# Sets up a temorary DNS server that will answer requests
# to the given hostname with the IP of this machine.

# If any command fails, stop:
set -e

# Let's get our IP:
my_ip=`hostname -I | cut -f 1 -d ' '`

# Other queries will be routed to cloudflares DNS:
external_dns=1.1.1.1

# If no hostname was provided, display a help text:
if (( $# < 1 )); then
	echo Please provide the hostname you want to resolve
	echo to this machines IP. 
	echo Example: dns-here.sh example.com
	exit
fi

# If this script was started manually, then we are outside
# docker. Lets do what is necessary on the host:
if (( $# < 2 )); then
	# Get rid of systemd-resolved which might be listening
	# on port 53 which we need:
	systemctl stop systemd-resolved
	# Backup the current resolv.conf:
	cp /etc/resolv.conf /tmp/dns-here-resolv.conf
	# Eat our own dog food:
	echo 'nameserver 127.0.0.1' > /etc/resolv.conf
	# Now run docker:
	docker run -p53:8888/udp --rm -it         \
	           -v $(pwd)/$0:/bin/dns-here.sh   \
	           debian:10-slim                  \
	           /bin/dns-here.sh $1 $external_dns $my_ip
	# When we return from docker, restore resolv.conf:
	cp /tmp/dns-here-resolv.conf /etc/resolv.conf
	# Re-enable systemd-resolved:
	systemctl start systemd-resolved
	exit
fi

# We are inside Docker. Lets do what is necessary
# here to set up unbound:

apt update
apt-get install -y --no-install-recommends unbound

cat << EOF > /etc/unbound/unbound.conf
server:
        port: 8888
        interface: 0.0.0.0
        access-control: 0.0.0.0/0 allow
        do-daemonize: no
        local-zone: "$1." redirect
        local-data: "$1. 180 IN A $3"
        verbosity: 2
        logfile: ""
forward-zone:
        name: .
        forward-addr: $2
EOF

unbound
