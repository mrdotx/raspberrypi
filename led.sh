#!/bin/sh

# path:   /home/klassiker/.local/share/repos/raspberrypi/led.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/raspberrypi
# date:   2022-02-01T10:01:49+0100

# speed up script by not using unicode
LC_ALL=C
LANG=C

# config
led0_path="/sys/class/leds/led0"
led1_path="/sys/class/leds/led1"
led0_default="mmc0"
led1_default="input"

script=$(basename "$0")
help="$script [-h/--help] -- script to change status leds
  Usage:
    $script [--green] [0/1] [--red] [0/1] [--defaults]

  Settings:
    --green    = set green led off [0] or on [1]
    --red      = set red led off [0] or on [1]
    --defaults = reset led settings to default values

  Example:
    $script --green 0
    $script --red 1
    $script --red 0 --green 1
    $script --defaults"

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
    check_root
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
        --defaults)
            check_root
            set_trigger "$led0_default" "$led0_path"
            set_trigger "$led1_default" "$led1_path"
            ;;
        --green)
            shift
            set_led "$1" "$led0_path"
            ;;
        --red)
            shift
            set_led "$1" "$led1_path"
            ;;
        *)
            print_help 1
            ;;
    esac
    shift
done
