#!/bin/sh

# path:   /home/klassiker/.local/share/repos/raspberrypi/padd_update.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/raspberrypi
# date:   2022-09-19T18:28:04+0200

# speed up script by using standard c
LC_ALL=C
LANG=C

output="$HOME/bin/padd.sh"
url="https://raw.githubusercontent.com/pi-hole/PADD/master/padd.sh"

replace() {
    sed -i "s?$1?$2?" "$output"
}

# download and set permissions
curl -o "$output" "$url"
chmod 755 "$output"

# replace shebang (\e[0K problem)
replace "#!/usr/bin/env sh" "#!/usr/bin/env bash"

# replace ftl database location
replace "/run/pihole-FTL.port" "/run/pihole-ftl/pihole-FTL.port"
