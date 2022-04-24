#!/bin/sh

# path:   /home/klassiker/.local/share/repos/raspberrypi/padd_update.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/raspberrypi
# date:   2022-04-24T08:01:38+0200

# speed up script by using standard c
LC_ALL=C
LANG=C

output="$HOME/bin/padd.sh"
url="https://raw.githubusercontent.com/pi-hole/PADD/master/padd.sh"

curl -o "$output" "$url"
chmod 755 "$output"
