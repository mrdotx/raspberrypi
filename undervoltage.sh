#!/bin/sh

# path:       /home/klassiker/.local/share/repos/raspberrypi/undervoltage.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/raspberrypi
# date:       2020-05-23T20:32:32+0200

# information for results
# 0: under-voltage
# 1: arm frequency capped
# 2: currently throttled

# 16: under-voltage has occurred
# 17: arm frequency capped has occurred
# 18: throttling has occurred

# bad values
# health state        vcore
# 1000000000000000000 1.3125V
# 1010000000000000000 1.3125V
# 1010000000000000101 1.2V
# 1010000000000000101 1.2V
# 1010000000000000101 1.2V
# 1010000000000000101 1.2V
# 1010000000000000000 1.3125V
# 1010000000000000000 1.3125V

# good values
# health state        vcore
# 0000000000000000000 1.3125V
# 0000000000000000000 1.3125V
# 0000000000000000000 1.3125V
# 0000000000000000000 1.3125V
# 0000000000000000000 1.3125V
# 0000000000000000000 1.3125V
# 0000000000000000000 1.3125V
# 0000000000000000000 1.3125V

vcgencmd="/opt/vc/bin/vcgencmd"
cpu_freq="/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
i=9
header="time     temp    cpu fake/real  health state        vcore"
while true; do
    i=$(( i + 1 ))
    [ "$i" -eq 10 ] \
        && printf "\n%s\n" "$header" \
        && i=0
    throttled=$($vcgencmd get_throttled \
        | cut -f2 -dx \
    )
    health=$(printf "obase=2; ibase=16; %s\n" "$throttled" \
        | bc \
    )
    temp=$($vcgencmd measure_temp \
        | cut -f2 -d= \
    )
    real_cs=$($vcgencmd measure_clock arm \
        | awk -F"=" '{printf ("%0.0f",$2/1000000); }' \
    )
    sys_cs=$(awk '{printf ("%0.0f",$1/1000); }' <$cpu_freq)
    v_core=$($vcgencmd measure_volts \
        | cut -f2 -d= \
        | sed 's/000//' \
    )
    printf "%s %s%5s/%4s MHz   %019d %s\n" "$(date "+%H:%M:%S")" "$temp" "$sys_cs" "$real_cs" "$health" "$v_core"
    sleep 5
done
