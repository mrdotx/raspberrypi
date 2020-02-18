#!/bin/sh

# path:       ~/projects/shell/raspberrypi/sys_stat.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/raspberrypi
# date:       2020-02-18T19:22:33+0100

script=$(basename "$0")
help="$script [-h/--help] -- script to show system status
  Usage:
    $script [settings]

  Settings:
    without given settings will show all informations
    h = header with hostname and time
    d = information about distribution, kernel, firmware
    s = system information about uptime, ethernet, processor, load, memory and hdd
    p = top 5 processes
    m = status main services ssh, pihole, dnscrypt, tor, cups, nginx
    t = systemd timers
    f = failures of systemd and journald
    c = check updates
    e = execution time of this script

  Example:
    $script hs
    $script hfc
    $script hm
    $script htm"

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "$help"
    exit 0
fi

if [ $# -eq 0 ]; then
    option=hdspmtfce
else
    option=$1
fi

# execution time
if [ -z "${option##*e*}" ]; then
    start=$(date +%s.%N)
fi

# header
if [ -z "${option##*h*}" ]; then
    echo "################################################################################"
    system_name=$(hostname &)
    standard_time=$(date +"%c" &)
    echo "[${system_name}] - ${standard_time}"
    echo "################################################################################"
    echo
fi

# distribution
if [ -z "${option##*d*}" ]; then
    echo "[Distribution]"
    echo "--------------------------------------------------------------------------------"
    name=$(awk -F '"' '/PRETTY_NAME/{print $2}' /etc/os-release &)
    kernel=$(uname -msr &)
    firmware=$(awk -F '#' '{print $2}' /proc/version &)
    echo "name:         ${name}"
    echo "kernel:       ${kernel}"
    echo "firmware:     #${firmware}"
    echo
fi

# system
if [ -z "${option##*s*}" ]; then
    echo "[System]"
    echo "--------------------------------------------------------------------------------"
    operating_time=$(uptime --pretty &)
    net_send=$(awk '{print $1/1024/1024/1024}' /sys/class/net/eth0/statistics/tx_bytes &)
    net_received=$(awk '{print $1/1024/1024/1024}' /sys/class/net/eth0/statistics/rx_bytes &)
    cpu=$(awk -F ": " '/Hardware/{print $2}' /proc/cpuinfo &)
    cpu_frequency=$(/opt/vc/bin/vcgencmd measure_clock arm | awk -F "=" '{printf ("%0.0f",$2/1000000); }' &)
    cpu_temp=$(/opt/vc/bin/vcgencmd measure_temp | awk -F '=' '{print $2}' &)
    voltage=$(/opt/vc/bin/vcgencmd measure_volts | awk -F '=' '{print $2}' | sed 's/000//' &)
    scaling_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor &)
    load_avg=$(awk -F ' ' '{print $1" "$2" "$3}' /proc/loadavg &)
    memory=$(free -h &)
    disc=$(df -hPT /boot / &)
    echo "uptime:       ${operating_time}"
    echo "ethernet:     sent: ${net_send}GB received: ${net_received}GB"
    echo "processor:    ${cpu} ${cpu_frequency}MHz ${voltage} ${scaling_governor} ${cpu_temp}"
    echo "load:         ${load_avg}"
    echo
    echo "${memory}"
    echo
    echo "${disc}"
    echo
fi

# processes
if [ -z "${option##*p*}" ]; then
    echo "[Top 5 Processes]"
    echo "--------------------------------------------------------------------------------"
    top_processes=$(ps -e -o pid,etimes,time,comm --sort -time | sed "6q" &)
    echo "${top_processes}"
    echo
fi

# main services
if [ -z "${option##*m*}" ]; then
    echo "[Services]"
    echo "--------------------------------------------------------------------------------"
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
    echo "Service           Status  Port            RunTime"
    service "sshd"; ports "22"
    echo "ssh               $status    22    $port    $runtime"
    service "pihole-FTL"; ports "53"
    echo "pihole            $status    53    $port    $runtime"
    service "dnscrypt-proxy"; ports "5300"
    echo "dnscrypt          $status    5300  $port    $runtime"
    service "tor"; ports "9050"
    echo "tor               $status    9050  $port    $runtime"
    service "org.cups.cupsd"; ports "631"
    echo "cups              $status    631   $port    $runtime"
    service "nginx"; ports "80"
    echo "nginx             $status    80    $port    $runtime"
    ports "443"
    echo "                          443   $port"
    echo
fi

# timers
if [ -z "${option##*t*}" ]; then
    echo "[Timers]"
    echo "--------------------------------------------------------------------------------"
    timers=$(systemctl list-timers --all)
    echo "${timers}" | fold
    echo
fi

# failures
if [ -z "${option##*f*}" ]; then
    echo "[Failures]"
    echo "--------------------------------------------------------------------------------"
    failures=$(systemctl --failed && journalctl -p 3 -xb &)
    echo "${failures}" | fold
    echo
fi

# check updates
if [ -z "${option##*c*}" ]; then
    echo "[Packages]"
    echo "--------------------------------------------------------------------------------"
    packages=$(checkupdates &)
    echo "${packages}"
    echo
fi

# execution time
if [ -z "${option##*e*}" ]; then
    echo "################################################################################"
    duration=$(echo "$(date +%s.%N) - $start" | bc)
    execution_time=$(printf "%.2f seconds" "$duration")
    echo "Script Execution Time: $execution_time"
    echo "################################################################################"
fi
