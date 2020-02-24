#!/bin/sh

# path:       ~/projects/shell/raspberrypi/stability.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/raspberrypi
# date:       2020-02-24T09:13:02+0100

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
    sudo dd if=/dev/mmcblk0 of=/dev/null bs=4M
done

printf ":: writes 512mb test file 5 times\n"
for i in $(seq 1 5); do
    printf " writing: %s\n" "$i"
    dd if=/dev/zero of=test.dat bs=1M count=512
    sync
done

printf ":: kill processes and delete test file\n"
sudo killall yes
rm test.dat

printf ":: summery\n"
printf " cpu freq: %s MHz\n" "$($vcgencmd measure_clock arm | awk -F"=" '{printf ("%0.0f",$2/1000000); }')"
printf " cpu temp: %s\n" "$($vcgencmd measure_temp | cut -f2 -d=)"
printf ":: check dmesg, the failures will be shown there\n"
dmesg | tail -n 5
