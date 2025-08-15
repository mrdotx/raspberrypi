#!/bin/sh

# path:   /home/klassiker/.local/share/repos/raspberrypi/led.sh
# author: klassiker [mrdotx]
# url:    https://github.com/mrdotx/raspberrypi
# date:   2025-08-15T03:37:42+0200

# speed up script by using standard c
LC_ALL=C
LANG=C

# config
# led0 = ACT (green), led1 = PWR (red)
led0_path="/sys/class/leds/led0"
led1_path="/sys/class/leds/led1"
# cat /sys/class/leds/led0/trigger
# none            cpu           kbd-scrolllock
# usb-gadget      cpu0          kbd-numlock
# usb-host        cpu1          kbd-capslock
# rfkill-any      cpu2          kbd-kanalock
# rfkill-none     cpu3          kbd-shiftlock
# timer           default-on    kbd-altgrlock
# oneshot         input         kbd-ctrllock
# heartbeat       panic         kbd-altlock
# backlight       actpwr        kbd-shiftllock
# gpio            mmc0          kbd-shiftrlock
#                               kbd-ctrlllock
#                               kbd-ctrlrlock
led0_default="mmc0"
led1_default="input"

script=$(basename "$0")
help="$script [-h/--help] -- script to change status leds
  Usage:
    $script [--act] [0/1] [--pwr] [0/1] [--defaults] [--status]

  Settings:
    --act      = set activity [green] led off [0] or on [1]
    --pwr      = set power [red] led off [0] or on [1]
    --defaults = reset led settings to default values
    --status   = displays status for brightness and trigger

  Example:
    $script --act 0
    $script --pwr 1
    $script --pwr 0 --act 1
    $script --defaults
    $script --status"

print_help() {
    printf "%s\n" "$help"
    exit "$1"
}

check_root() {
    [ "$(id -u)" -ne 0 ] \
        && printf "this script needs root privileges to run\n" \
        && exit 1
}

set_trigger() {
    grep -q "\[$1\]" "$2/trigger" \
        || printf "%s\n" "$1" > "$2/trigger"
}

set_led() {
    set_trigger "none" "$2"
    if [ "$1" = 0 ] || [ "$1" = 1 ]; then
        printf "%s\n" "$1" > "$2/brightness"
    else
        print_help 1
    fi
}

[ -z "$1" ] \
    && print_help 1

while [ $# -ge 1 ]; do
    case "$1" in
        -h | --help)
            print_help 0
            ;;
        --act)
            check_root
            shift
            set_led "$1" "$led0_path"
            ;;
        --pwr)
            check_root
            shift
            set_led "$1" "$led1_path"
            ;;
        --defaults)
            check_root
            set_trigger "$led0_default" "$led0_path"
            set_trigger "$led1_default" "$led1_path"
            ;;
        --status)
            printf "setting ACT LED to brightness %s with trigger %s\n" \
                "$(cat "$led0_path/brightness")" \
                "$(grep -oP '\[\K[^\]]+' "$led0_path/trigger")"
            printf "setting PWR LED to brightness %s with trigger %s\n" \
                "$(cat "$led1_path/brightness")" \
                "$(grep -oP '\[\K[^\]]+' "$led1_path/trigger")"
            ;;
        *)
            print_help 1
            ;;
    esac
    shift
done
