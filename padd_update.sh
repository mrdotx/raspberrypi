#!/bin/sh

# path:   /home/klassiker/.local/share/repos/raspberrypi/padd_update.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/raspberrypi
# date:   2022-04-21T10:37:10+0200

# speed up script by using posix
LC_ALL=C
LANG=C

output="$HOME/bin/padd.sh"
url="https://raw.githubusercontent.com/pi-hole/PADD/master/padd.sh"

curl -o "$output" "$url"
chmod 755 "$output"
