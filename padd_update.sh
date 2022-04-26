#!/bin/sh

# path:   /home/klassiker/.local/share/repos/raspberrypi/padd_update.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/raspberrypi
# date:   2022-04-26T19:20:27+0200

# speed up script by using standard c
LC_ALL=C
LANG=C

output="$HOME/bin/padd.sh"
url="https://raw.githubusercontent.com/pi-hole/PADD/master/padd.sh"

# download and set permissions
curl -o "$output" "$url"
chmod 755 "$output"

# replace ftl database loaction
search="\/run\/pihole-FTL.port"
replace="\/run\/pihole-ftl\/pihole-FTL.port"
sed -i "s/$search/$replace/g" "$output"
