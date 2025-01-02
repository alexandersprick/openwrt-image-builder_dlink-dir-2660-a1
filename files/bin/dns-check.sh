#!/bin/sh

# if DNS for google.de fails 6 times,
# restart wan interface by changing the interface name
# and reload network. UCI is clever enough to restart wan only.

restart_wan() {
    echo "Restart wan interface after DNS resolution failure..."
    r=$(/bin/date | /usr/bin/md5sum | /usr/bin/cut -c 1-8)
    /sbin/uci set network.wan.hostname="owrt${r}"
    /sbin/uci commit network
    /etc/init.d/network reload
}

while true; do
    sleep 60
    # make sure the interface is up
    uci -P /var/state -q get network.wan.up || continue
    # allow not more than 6 consecutive fails
    for count in $(seq 1 6); do
        sleep 10
        nslookup -query=ns google.de >/dev/null && break
        [ "${count}" = "6" ] && restart_wan
    done
done
