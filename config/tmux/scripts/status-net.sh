#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# tmux status pill: network link + VPN state
#
# Why this exists: the old inline
#     #(ip -o route get 1.1.1.1 | awk '{print $5}')
# printed whatever field 5 happened to be. That is the interface name only while
# the route is plain. Add a VPN with policy routing and the kernel prints
#    1.1.1.1 dev wg0 table 51820 src 10.8.0.2 ...
# so field 5 became the routing table id ("random numbers").
#
# This script parses `dev` explicitly and labels the link with the connection
# name (SSID / device) instead of the raw kernel interface. It also detects
# VPNs that NetworkManager does not manage (Tailscale, Mullvad CLI, wg-quick).
#
# Output examples:   󰖩 2 BROTHERS CONNECT       󰈀 enp3s0
#                    󰖩 2 BROTHERS CONNECT 󰒄 mullvad
#                    󰖪 offline
# ------------------------------------------------------------------------------

set -u

ICON_WIFI=$'\U000F05A9'   # 󰖩
ICON_ETH=$'\U000F0200'    # 󰈀
ICON_VPN=$'\U000F0484'    # 󰒄
ICON_OFF=$'\U000F05AA'    # 󰖪

cache_dir="${XDG_RUNTIME_DIR:-/tmp}/tmux-status"
mkdir -p -- "$cache_dir" 2>/dev/null || cache_dir=/tmp

# --- Bridge a string to a fixed width ----------------------------------------
trunc() {
    local s=$1 max=${2:-16}
    if (( ${#s} > max )); then
        printf '%s…' "${s:0:max-1}"
    else
        printf '%s' "$s"
    fi
}

# --- Cached NetworkManager snapshot (nmcli costs ~40-80 ms) -------------------
nm_cache="$cache_dir/nmcli-active"
refresh=1
if [[ -s $nm_cache ]]; then
    now=$(printf '%(%s)T' -1)
    mtime=$(stat -c %Y -- "$nm_cache" 2>/dev/null || echo 0)
    (( now - mtime < 10 )) && refresh=0
fi
if (( refresh )) && command -v nmcli >/dev/null 2>&1; then
    nmcli -t -f NAME,TYPE,DEVICE connection show --active >| "$nm_cache" 2>/dev/null
fi

# NAME may contain escaped colons, TYPE and DEVICE may not, so split from the
# right: NAME:TYPE:DEVICE
vpn_name='' wifi_name='' eth_dev=''
if [[ -s $nm_cache ]]; then
    while IFS= read -r line; do
        [[ -z $line ]] && continue
        dev=${line##*:}
        rest=${line%:*}
        type=${rest##*:}
        name=${rest%:*}
        case $type in
            vpn|wireguard)    [[ -z $vpn_name  ]] && vpn_name=$name ;;
            802-11-wireless)  [[ -z $wifi_name ]] && wifi_name=$name ;;
            802-3-ethernet)   [[ -z $eth_dev   ]] && eth_dev=$dev ;;
        esac
    done <"$nm_cache"
fi

# --- VPN tunnels not managed by NetworkManager -------------------------------
# Pure shell glob over /sys/class/net: no forks.
tunnel=''
for link in /sys/class/net/*; do
    name=${link##*/}
    case $name in
        tun*|tap*|wg*|tailscale*|nordlynx*|ipsec*|ppp*|proton*|utun*)
            tunnel=$name
            break
            ;;
    esac
done

# --- Default route interface, parsed field by field (no awk $N guessing) -----
route_if=''
if [[ -r /proc/net/route ]]; then
    while read -r iface dest _; do
        if [[ $dest == 00000000 ]]; then
            route_if=$iface
            break
        fi
    done </proc/net/route
fi

# --- Compose -----------------------------------------------------------------
vpn_label=''
if [[ -n $vpn_name ]]; then
    vpn_label=$vpn_name
elif [[ -n $tunnel ]]; then
    vpn_label=$tunnel
fi

if [[ -n $wifi_name ]]; then
    link="$ICON_WIFI $(trunc "$wifi_name" 18)"
elif [[ -n $eth_dev ]]; then
    link="$ICON_ETH $(trunc "$eth_dev" 16)"
elif [[ -n $route_if ]]; then
    link="$ICON_ETH $(trunc "$route_if" 16)"
else
    link="$ICON_OFF offline"
fi

if [[ -n $vpn_label ]]; then
    printf '%s %s %s' "$link" "$ICON_VPN" "$(trunc "$vpn_label" 14)"
else
    printf '%s' "$link"
fi
