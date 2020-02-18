#!/bin/sh

# path:       ~/projects/shell/raspberrypi/undervoltage.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/raspberrypi
# date:       2020-02-18T19:06:20+0100

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
echo "to stop press [ctrl]-[c]"
i=14
header="time     temp    cpu fake/real  health state        vcore"
while true; do
    i=$(( i + 1 ))
    if [ "$i" -eq 15 ]; then
        echo "$header"
        i=0
    fi
    throttled=$($vcgencmd get_throttled | cut -f2 -dx)
    health=$(echo "obase=2; ibase=16; $throttled" | bc)
    temp=$($vcgencmd measure_temp | cut -f2 -d=)
    real_cs=$($vcgencmd measure_clock arm | awk -F"=" '{printf ("%0.0f",$2/1000000); }')
    sys_cs=$(awk '{printf ("%0.0f",$1/1000); }' <$cpu_freq)
    v_core=$($vcgencmd measure_volts | cut -f2 -d= | sed 's/000//')
    echo "$(date "+%H:%M:%S") $temp$(printf "%5s" "$sys_cs")/$(printf "%4s" "$real_cs") MHz   $(printf "%019d" "$health") $v_core"
    sleep 5
done
