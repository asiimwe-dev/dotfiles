#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# tmux status pill: CPU + RAM
#
# Replaces `top -bn1 | awk ...` and `free -m | awk ...`, which forked two
# heavyweight processes every status-interval (~0.3-0.8 s each, continuously).
# Everything here is read straight from /proc, with the previous CPU sample
# cached so the percentage is a delta, not load-average noise.
# ------------------------------------------------------------------------------

set -u

ICON_CPU=$'\U000F4BC'    # CPU
ICON_RAM=$'\U000F035B'   # 󰍛

cache_dir="${XDG_RUNTIME_DIR:-/tmp}/tmux-status"
mkdir -p -- "$cache_dir" 2>/dev/null || cache_dir=/tmp
sample="$cache_dir/cpu-sample"

# --- CPU: delta of (total - idle) since the previous call ---------------------
read -r _cpu u n s i w irq sirq steal _ < /proc/stat
idle_all=$(( i + w ))
non_idle=$(( u + n + s + irq + sirq + steal ))
total=$(( idle_all + non_idle ))

cpu='--'
if [[ -s $sample ]] && read -r prev_total prev_idle <"$sample"; then
    dt=$(( total - prev_total ))
    di=$(( idle_all - prev_idle ))
    if (( dt > 0 )); then
        cpu=$(( 100 * (dt - di) / dt ))
    fi
fi
printf '%s %s\n' "$total" "$idle_all" >|"$sample"

# --- RAM: MemAvailable accounts for reclaimable cache ------------------------
mem_total=0
mem_avail=0
while read -r key value _; do
    case $key in
        MemTotal:)     mem_total=$value ;;
        MemAvailable:) mem_avail=$value; break ;;
    esac
done </proc/meminfo
ram=0
(( mem_total > 0 )) && ram=$(( (mem_total - mem_avail) * 100 / mem_total ))

if [[ $cpu == -- ]]; then
    printf '%s --  %s %s%%' "$ICON_CPU" "$ICON_RAM" "$ram"
else
    printf '%s %s%%  %s %s%%' "$ICON_CPU" "$cpu" "$ICON_RAM" "$ram"
fi
