#!/bin/sh

# path:   /home/klassiker/.local/share/repos/raspberrypi/undervoltage.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/raspberrypi
# date:   2022-03-02T09:09:23+0100

# speed up script by not using unicode
LC_ALL=C
LANG=C

# config
vcgencmd="/opt/vc/bin/vcgencmd"
cpu_freq="/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
header_repeat=10
measuring_interval=5

# information about results
# 0: under-voltage
# 1: arm frequency capped
# 2: currently throttled

# 16: under-voltage has occurred
# 17: arm frequency capped has occurred
# 18: throttling has occurred

# bad value
# health state        vcore
# 1010000000000000101 1.2V

# ambiguous value
# health state        vcore
# 1010000000000000000 1.3125V

# good value
# health state        vcore
# 0000000000000000000 1.3125V

get_throttled() {
    $vcgencmd get_throttled \
        | cut -f2 -dx
}

get_health() {
    printf "obase=2; ibase=16; %s\n" "$(get_throttled)" \
        | bc
}

get_temp() {
    $vcgencmd measure_temp \
        | cut -f2 -d=
}

get_real_cs() {
    $vcgencmd measure_clock arm \
        | awk -F"=" '{printf ("%0.0f",$2/1000000); }'
}

get_sys_cs() {
    awk '{printf ("%0.0f",$1/1000); }' <$cpu_freq
}

get_v_core() {
    $vcgencmd measure_volts \
        | cut -f2 -d= \
        | sed 's/000//'
}

i=$((header_repeat - 1))
while true; do
    i=$((i + 1))
    [ "$i" -eq $header_repeat ] \
        && printf \
            "\ntime      temp    cpu fake/real  health state         vcore\n" \
        && i=0
    printf "%s  %s %5s/%4s MHz  %019d  %s\n" \
        "$(date "+%H:%M:%S")" \
        "$(get_temp)" \
        "$(get_sys_cs)" \
        "$(get_real_cs)" \
        "$(get_health)" \
        "$(get_v_core)"
    sleep $measuring_interval
done
