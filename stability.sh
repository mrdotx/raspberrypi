#!/bin/sh

# path:   /home/klassiker/.local/share/repos/raspberrypi/stability.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/raspberrypi
# date:   2021-01-15T13:53:00+0100

# auth can be something like sudo -A, doas -- or
# nothing, depending on configuration requirements
auth="doas"
vcgencmd="/opt/vc/bin/vcgencmd"
cores=$(($(nproc --all) - 1))

printf ":: heat up all cpu cores to stress the power-supply\n"
for i in $(seq 0 $cores); do
    printf " core: %s\n" "$i"
    nice yes >/dev/null &
done

printf ":: read the entire sd card 5 times\n"
for i in $(seq 1 5); do
    printf " reading: %s\n" "$i"
    $auth dd if=/dev/mmcblk0 of=/dev/null bs=4M
done

printf ":: writes 512mb test file 5 times\n"
for i in $(seq 1 5); do
    printf " writing: %s\n" "$i"
    dd if=/dev/zero of=test.dat bs=1M count=512
    sync
done

printf ":: kill processes and delete test file\n"
$auth killall yes
rm test.dat

printf ":: summery\n"
printf " cpu freq: %s MHz\n" "$($vcgencmd measure_clock arm \
        | awk -F"=" '{printf ("%0.0f",$2/1000000); }' \
    )"
printf " cpu temp: %s\n" "$($vcgencmd measure_temp \
        | cut -f2 -d= \
    )"
printf ":: check dmesg, the failures will be shown there\n"
dmesg | tail -n 5
