#!/bin/sh

# path:   /home/klassiker/.local/share/repos/raspberrypi/stability.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/raspberrypi
# date:   2025-04-02T06:35:46+0200

vcgencmd="/opt/vc/bin/vcgencmd"
cores=$(($(nproc --all) - 1))

# speed up script by using standard c
LC_ALL=C
LANG=C

# auth can be something like sudo -A, doas -- or nothing,
# depending on configuration requirements
auth="${EXEC_AS_USER:-sudo}"

# color variables
reset="\033[0m"
bold="\033[1m"
green="\033[32m"
blue="\033[94m"

printf "%b%b::%b %bheat up all cpu cores to stress the power-supply%b\n" \
    "$bold" "$blue" "$reset" "$bold" "$reset"
for i in $(seq 0 $cores); do
    printf " core: %s\n" "$i"
    nice yes >/dev/null &
done

printf "%b%b::%b %bread the entire sd card 5 times%b\n" \
    "$bold" "$blue" "$reset" "$bold" "$reset"
for i in $(seq 1 5); do
    printf " reading: %s\n" "$i"
    $auth dd if=/dev/mmcblk0 of=/dev/null bs=4M
done

printf "%b%b::%b %bwrite 512mb test file 5 times%b\n" \
    "$bold" "$blue" "$reset" "$bold" "$reset"
for i in $(seq 1 5); do
    printf " writing: %s\n" "$i"
    dd if=/dev/zero of=test.dat bs=1M count=512
    sync
done

printf "%b%b::%b %bkill processes and delete the test file%b\n" \
    "$bold" "$blue" "$reset" "$bold" "$reset"
$auth killall yes
rm test.dat

printf "%b%b::%b %bsummery%b\n" \
    "$bold" "$blue" "$reset" "$bold" "$reset"
printf " cpu freq: %s MHz\n" "$($vcgencmd measure_clock arm \
        | awk -F"=" '{printf ("%0.0f",$2/1000000); }' \
    )"
printf " cpu temp: %s\n" "$($vcgencmd measure_temp \
        | cut -f2 -d= \
    )"
printf "%b%b==>%b check dmesg for malfunctions\n" \
    "$bold" "$green" "$reset"
dmesg | tail -n 5
