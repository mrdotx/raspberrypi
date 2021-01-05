#!/bin/sh

# path:       /home/klassiker/.local/share/repos/raspberrypi/sys_stat.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/raspberrypi
# date:       2021-01-05T14:02:45+0100

script=$(basename "$0")
help="$script [-h/--help] -- script to show system status
  Usage:
    $script [settings]

  Settings:
    without given settings, will show all informations
    -n = header with hostname and time
    -d = information about distribution, kernel, firmware
    -s = system information about uptime, ethernet, processor, load, memory and hdd
    -p = top 5 processes
    -m = status main services ssh, pihole, unbound, tor, cups, nginx
    -t = systemd timers
    -f = failures of systemd and journald
    -c = check updates
    -e = footer with hostname and time

  Example:
    $script -ns
    $script -nfc
    $script -nm
    $script -ntm"

if [ "$1" = "-h" ] \
    || [ "$1" = "--help" ]; then
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
            exit 1
            ;;
    esac
fi

line() {
    printf "%s\n" "================================================================================"
}

header() {
    printf "[%s] - %s\n" \
        "$(hostname)" \
        "$(date +"%c")"
}

distribution() {
    printf "name:         %s\n" \
        "$(awk -F '"' '/PRETTY_NAME/{print $2}' /etc/os-release)"
    printf "kernel:       %s\n" \
        "$(uname -msr)"
    printf "firmware:     #%s\n" \
        "$(cut -d '#' -f2 /proc/version)"
    # shellcheck disable=SC2012
    printf "shell link:   %s\n\n" \
        "$(ls -lha /bin/sh \
            | cut -d ' ' -f9-11 \
        )"
}

system() {
    dns_value() {
        dig +short chaos txt "$1".bind \
            | tr -d "\""
    }
    printf "uptime:       %s\n" \
        "$(uptime --pretty)"
    printf "ethernet:     sent: %s received: %s\n" \
        "$(awk '{if ($1/1024/1024 < 1073741824) print $1/1024/1024 "MB"; else print $1/1024/1024/1024 "GB";}' \
            /sys/class/net/eth0/statistics/tx_bytes)" \
            "$(awk '{if ($1/1024/1024 < 1073741824) print $1/1024/1024 "MB"; else print $1/1024/1024/1024 "GB";}' \
            /sys/class/net/eth0/statistics/rx_bytes)"
    printf "dns:          cachesize: %d insertions: %d evictions: %d\n" \
        "$(dns_value cachesize)" \
        "$(dns_value insertions)" \
        "$(dns_value evictions)"
    printf "processor:    %s %sMHz %s %s %s\n" \
        "$(awk -F ": " '/Hardware/{print $2}' /proc/cpuinfo)" \
        "$(/opt/vc/bin/vcgencmd measure_clock arm \
            | awk -F "=" '{printf ("%0.0f",$2/1000000); }')" \
        "$(/opt/vc/bin/vcgencmd measure_volts \
            | cut -d '=' -f2 \
            | sed 's/000//' \
        )" \
        "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" \
        "$(/opt/vc/bin/vcgencmd measure_temp \
            | cut -d '=' -f2 \
        )"
    printf "load:         %s\n\n" \
        "$(cut -d ' ' -f1-3 /proc/loadavg)"
    printf "%s\n\n" \
        "$(free -h)"
    printf "%s\n\n" \
        "$(df -hPT /boot /)"
}

processes() {
    printf "%s\n\n" \
        "$(ps -e -o pid,etimes,time,comm --sort -time \
            | sed "$(($1+1))q" \
        )"
}

services() {
    service() {
        if [ "$(systemctl is-active "$1")" = "active" ]; then
            status="up  "
            runtime="$(systemctl status "$1" \
                    | awk -F '; ' 'FNR == 3 {print $NF}' \
                )"
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
    printf "ssh               %s    22    %s    %s\n" \
        "$status" \
        "$port" \
        "$runtime"
    service "pihole-FTL"; ports "53"
    printf "pihole            %s    53    %s    %s\n" \
        "$status" \
        "$port" \
        "$runtime"
    service "unbound"; ports "5335"
    printf "unbound           %s    5335  %s    %s\n" \
        "$status" \
        "$port" \
        "$runtime"
    service "tor"; ports "9050"
    printf "tor               %s    9050  %s    %s\n" \
        "$status" \
        "$port" \
        "$runtime"
    service "cups"; ports "631"
    printf "cups              %s    631   %s    %s\n" \
        "$status" \
        "$port" \
        "$runtime"
    service "nginx"; ports "80"
    printf "nginx             %s    80    %s    %s\n" \
        "$status" \
        "$port" \
        "$runtime"
    ports "443"
    printf "                          443   %s\n\n" \
        "$port"
}

timers() {
    printf "%s\n\n" \
        "$(systemctl list-timers --all \
            | fold -s \
        )"
}

failures() {
    printf "%s\n%s\n\n" \
        "$(systemctl --failed \
            | fold -s \
        )" \
        "$(journalctl -p 3 -xb \
            | fold -s \
        )"
}

updates() {
    printf "%s\n%s\n\n" \
        "$(checkupdates)" \
        "$(paru -Qua)"
}

footer() {
    printf "[%s] - %s\n" \
        "$(hostname)" \
        "$(date +"%c")"
}

[ -z "${option##*n*}" ] \
    && line \
    && header \
    && line \
    && printf "\n"
[ -z "${option##*d*}" ] \
    && printf "[Distribution]\n" \
    && line \
    && distribution \
[ -z "${option##*s*}" ] \
    && printf "[System]\n" \
    && line \
    && system \
[ -z "${option##*p*}" ] \
    && top=5 \
    && printf "[Top %d Processes]\n" "$top" \
    && line \
    && processes $top
[ -z "${option##*m*}" ] \
    && printf "[Services]\n" \
    && line \
    && services
[ -z "${option##*t*}" ] \
    && printf "[Timers]\n" \
    && line \
    && timers
[ -z "${option##*f*}" ] \
    && printf "[Failures]\n" \
    && line \
    && failures
[ -z "${option##*c*}" ] \
    && printf "[Packages]\n" \
    && line \
    && updates
[ -z "${option##*e*}" ] \
    && line \
    && footer \
    && line
