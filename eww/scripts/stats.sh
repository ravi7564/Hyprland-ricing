#!/bin/bash

# --- Configuration ---
NETWORK_INTERFACE="wlp4s0"

# --- Helper Functions ---
format_net_speed() {
    local bytes=$1
    if (( $(echo "$bytes < 1048576" | bc -l) )); then
        awk "BEGIN {printf \"%.1f KB/s\", $bytes/1024}"
    else
        awk "BEGIN {printf \"%.1f MB/s\", $bytes/1048576}"
    fi
}

# --- Data-Gathering Functions ---

get_cpu_usage() {
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    local total_idle=$((idle + iowait)); local total_time=$((user + nice + system + idle + iowait + irq + softirq + steal))
    local diff_idle=$((total_idle - last_total_idle)); local diff_total=$((total_time - last_total_time))
    local usage=$(( (1000 * (diff_total - diff_idle) / diff_total + 5) / 10 ))
    echo "${usage}"
    last_total_idle=$total_idle; last_total_time=$total_time
}

get_temperature() {
    local temp_file="/sys/class/thermal/thermal_zone0/temp"
    if [[ -f "$temp_file" && -r "$temp_file" ]]; then
        local temp_value; temp_value=$(head -n 1 "$temp_file")
        if [[ "$temp_value" =~ ^[0-9]+$ ]]; then echo "$((temp_value / 1000))"; else echo "0"; fi
    else echo "0"; fi
}

get_gpu_usage() {
    if command -v nvidia-smi &> /dev/null; then nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits; else echo "0"; fi
}

get_memory() {
    local ram_perc ram_used ram_total
    ram_perc=$(free | awk '/Mem/ {printf "%.0f", $3/$2 * 100.0}')
    ram_used=$(free -h | awk '/Mem/ {print $3}' | sed 's/Gi/GB/;s/Mi/MB/')
    ram_total=$(free -h | awk '/Mem/ {print $2}' | sed 's/Gi/GB/;s/Mi/MB/')
    echo "$ram_perc $ram_used $ram_total"
}

get_disk() {
    local disk_perc disk_used disk_total
    disk_perc=$(df --output=pcent / | awk 'NR==2 {sub(/%/, ""); print}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    echo "$disk_perc $disk_used $disk_total"
}

get_network() {
    if [[ -d "/sys/class/net/$NETWORK_INTERFACE" ]]; then
        local current_time current_rx current_tx
        current_time=$(date +%s%N); current_rx=$(cat "/sys/class/net/$NETWORK_INTERFACE/statistics/rx_bytes"); current_tx=$(cat "/sys/class/net/$NETWORK_INTERFACE/statistics/tx_bytes")
        local time_diff=$((current_time - last_net_time))
        if (( time_diff > 0 )); then
            local rx_speed=$(((current_rx - last_rx_bytes) * 1000000000 / time_diff)); local tx_speed=$(((current_tx - last_tx_bytes) * 1000000000 / time_diff))
            # CORRECTED: Using a comma to separate the values
            echo "$(format_net_speed "$rx_speed"),$(format_net_speed "$tx_speed")"
        else echo "0 KB/s,0 KB/s"; fi
        last_net_time=$current_time; last_rx_bytes=$current_rx; last_tx_bytes=$current_tx
    else echo "Offline,Offline"; fi
}

# --- Initialization ---
read -r cpu last_user last_nice last_system last_idle last_iowait last_irq last_softirq last_steal last_guest last_guest_nice < /proc/stat
last_total_idle=$((last_idle + last_iowait)); last_total_time=$((last_user + last_nice + last_system + last_idle + last_iowait + last_irq + last_softirq + last_steal))
if [[ -d "/sys/class/net/$NETWORK_INTERFACE" ]]; then
    last_net_time=$(date +%s%N); last_rx_bytes=$(cat "/sys/class/net/$NETWORK_INTERFACE/statistics/rx_bytes"); last_tx_bytes=$(cat "/sys/class/net/$NETWORK_INTERFACE/statistics/tx_bytes")
fi

# --- Main Loop ---
while true; do
    cpu_usage=$(get_cpu_usage)
    cpu_temp=$(get_temperature)
    gpu_perc=$(get_gpu_usage)
    read -r ram_perc ram_used ram_total <<< "$(get_memory)"
    read -r disk_perc disk_used disk_total <<< "$(get_disk)"
    # CORRECTED: Telling read to use a comma as the separator
    IFS=',' read -r net_down net_up <<< "$(get_network)"

    # Assemble and print the JSON output
    echo "{\"cpu\": ${cpu_usage:-0}, \
           \"temp\": ${cpu_temp:-0}, \
           \"gpu_perc\": ${gpu_perc:-0}, \
           \"ram_perc\": ${ram_perc:-0}, \
           \"ram_used\": \"${ram_used:-0B}\", \
           \"ram_total\": \"${ram_total:-0B}\", \
           \"disk_perc\": ${disk_perc:-0}, \
           \"disk_used\": \"${disk_used:-0B}\", \
           \"disk_total\": \"${disk_total:-0B}\", \
           \"net_down\": \"${net_down}\", \
           \"net_up\": \"${net_up}\"}"
           
    sleep 1
done
