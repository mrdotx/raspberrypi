#!/bin/sh

# path:       ~/repos/shell/raspberrypi/sys_stat.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/raspberrypi
# date:       2020-02-28T08:20:10+0100

script=$(basename "$0")
help="$script [-h/--help] -- script to show system status
  Usage:
    $script [settings]

  Settings:
    without given settings will show all informations
    -n = header with hostname and time
    -d = information about distribution, kernel, firmware
    -s = system information about uptime, ethernet, processor, load, memory and hdd
    -p = top 5 processes
    -m = status main services ssh, pihole, dnscrypt, tor, cups, nginx
    -t = systemd timers
    -f = failures of systemd and journald
    -c = check updates
    -e = execution time of this script

  Example:
    $script -ns
    $script -nfc
    $script -nm
    $script -ntm"

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "%s\n" "$help"
    exit 0
fi

if [ $# -eq 0 ]; then
    option="ndspmtfce"
else
    case "$1" in
        -*)
            option="$1"
            ;;
        *)
            printf "%s\n" "$help"
            exit 0
            ;;
    esac
fi

start_time() {
    start=$(date +%s.%N)
}

line() {
    printf "%s\n" "================================================================================"
}

header() {
    printf "[%s] - %s\n" "$(hostname)" "$(date +"%c")"
}

distribution() {
    printf "name:         %s\n" "$(awk -F '"' '/PRETTY_NAME/{print $2}' /etc/os-release)"
    printf "kernel:       %s\n" "$(uname -msr)"
    printf "firmware:     #%s\n\n" "$(awk -F '#' '{print $2}' /proc/version)"
}

system() {
    printf "uptime:       %s\n" "$(uptime --pretty)"
    printf "ethernet:     sent: %s received: %s\n" \
        "$(awk '{if < 1073741824) print $1/1024/1024 "MB"; else print $1/1024/1024/1024 "GB";}' \
            /sys/class/net/eth0/statistics/tx_bytes)" \
        "$(awk '{if < 1073741824) print $1/1024/1024 "MB"; else print $1/1024/1024/1024 "GB";}' \
            /sys/class/net/eth0/statistics/rx_bytes)"
    printf "processor:    %s %sMHz %s %s %s\n" \
        "$(awk -F ": " '/Hardware/{print $2}' /proc/cpuinfo)" \
        "$(/opt/vc/bin/vcgencmd measure_clock arm | awk -F "=" '{printf ("%0.0f",$2/1000000); }')" \
        "$(/opt/vc/bin/vcgencmd measure_volts | awk -F '=' '{print $2}' | sed 's/000//')" \
        "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" \
        "$(/opt/vc/bin/vcgencmd measure_temp | awk -F '=' '{print $2}')"
    printf "load:         %s\n\n" "$(awk -F ' ' '{print $1" "$2" "$3}' /proc/loadavg)"
    printf "%s\n\n" "$(free -h)"
    printf "%s\n\n" "$(df -hPT /boot /)"
}

processes() {
    printf "%s\n\n" "$(ps -e -o pid,etimes,time,comm --sort -time | sed "$(($1+1))q")"
}

services() {
    service() {
        if [ "$(systemctl is-active "$1")" = "active" ]; then
            status="up  "
            runtime="$(systemctl status "$1" | awk -F '; ' 'FNR == 3 {print $NF}')"
        else
            status="down"
            runtime="-"
        fi
    }
    ports() {
        if ss -nlt | grep -q ":$1 "; then
            port="open  "
        else
            port="closed"
        fi
    }
    printf "Service           Status  Port            RunTime\n"
    service "sshd"; ports "22"
    printf "ssh               %s    22    %s    %s\n" "$status" "$port" "$runtime"
    service "pihole-FTL"; ports "53"
    printf "pihole            %s    53    %s    %s\n" "$status" "$port" "$runtime"
    service "dnscrypt-proxy"; ports "5300"
    printf "dnscrypt          %s    5300  %s    %s\n" "$status" "$port" "$runtime"
    service "tor"; ports "9050"
    printf "tor               %s    9050  %s    %s\n" "$status" "$port" "$runtime"
    service "org.cups.cupsd"; ports "631"
    printf "cups              %s    631   %s    %s\n" "$status" "$port" "$runtime"
    service "nginx"; ports "80"
    printf "nginx             %s    80    %s    %s\n" "$status" "$port" "$runtime"
    ports "443"
    printf "                          443   %s\n\n" "$port"
}

timers() {
    printf "%s\n\n" "$(systemctl list-timers --all | fold)"
}

failures() {
    printf "%s\n\n" "$(systemctl --failed | fold && journalctl -p 3 -xb | fold)"
}

updates() {
    printf "%s\n\n" "$(checkupdates)"
}

end_time() {
    printf "Script Execution Time: %s\n" "$(date -u -d "0 $(date +%s.%N) sec - $start sec" +"%H:%M:%S.%3N")"
}

if [ -z "${option##*e*}" ]; then
    start_time
fi
if [ -z "${option##*n*}" ]; then
    line
    header
    line
    printf "\n"
fi
if [ -z "${option##*d*}" ]; then
    printf "[Distribution]\n"
    line
    distribution
fi
if [ -z "${option##*s*}" ]; then
    printf "[System]\n"
    line
    system
fi
if [ -z "${option##*p*}" ]; then
    top=5
    printf "[Top %d Processes]\n" "$top"
    line
    processes $top
fi
if [ -z "${option##*m*}" ]; then
    printf "[Services]\n"
    line
    services
fi
if [ -z "${option##*t*}" ]; then
    printf "[Timers]\n"
    line
    timers
fi
if [ -z "${option##*f*}" ]; then
    printf "[Failures]\n"
    line
    failures
fi
if [ -z "${option##*c*}" ]; then
    printf "[Packages]\n"
    line
    updates
fi
if [ -z "${option##*e*}" ]; then
    line
    end_time
    line
fi
