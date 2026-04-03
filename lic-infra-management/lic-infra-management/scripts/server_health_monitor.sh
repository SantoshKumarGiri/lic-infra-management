#!/bin/bash
# ============================================================
# Script   : server_health_monitor.sh
# Purpose  : Monitor server health metrics — CPU, Memory,
#            Disk, and running services
# Author   : Santosh Kumar Giri
# Project  : LIC Linux Infrastructure Management
# ============================================================

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── Thresholds ──
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85

# ── Report file ──
REPORT_DIR="./reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/health_report_$(date +%Y%m%d_%H%M%S).txt"

# ── Log file ──
LOG_DIR="./logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/monitor.log"

# ── Helper: log message ──
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

# ── Helper: print section header ──
header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# ── Helper: status badge ──
status_badge() {
    local value=$1
    local threshold=$2
    local label=$3
    if [ "$value" -ge "$threshold" ]; then
        echo -e "${RED}[CRITICAL]${NC} $label: ${value}% (Threshold: ${threshold}%)"
        log "CRITICAL - $label usage at ${value}%"
    elif [ "$value" -ge $((threshold - 15)) ]; then
        echo -e "${YELLOW}[WARNING] ${NC} $label: ${value}% (Threshold: ${threshold}%)"
        log "WARNING  - $label usage at ${value}%"
    else
        echo -e "${GREEN}[OK]      ${NC} $label: ${value}% (Threshold: ${threshold}%)"
        log "OK       - $label usage at ${value}%"
    fi
}

# ============================================================
# 1. SYSTEM INFO
# ============================================================
header "SYSTEM INFORMATION"
echo "Hostname     : $(hostname)"
echo "OS           : $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo "Kernel       : $(uname -r)"
echo "Uptime       : $(uptime -p)"
echo "Date & Time  : $(date)"
echo "Logged Users : $(who | wc -l)"

# ============================================================
# 2. CPU USAGE
# ============================================================
header "CPU USAGE"
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
# Fallback if top format differs
if [ -z "$CPU_USAGE" ]; then
    CPU_USAGE=$(vmstat 1 1 | tail -1 | awk '{print 100 - $15}')
fi
status_badge "$CPU_USAGE" "$CPU_THRESHOLD" "CPU"
echo "Load Average : $(cat /proc/loadavg | awk '{print $1, $2, $3}')"

# ============================================================
# 3. MEMORY USAGE
# ============================================================
header "MEMORY USAGE"
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
USED_MEM=$(free -m | awk '/^Mem:/{print $3}')
MEMORY_USAGE=$(awk "BEGIN {printf \"%d\", ($USED_MEM/$TOTAL_MEM)*100}")
status_badge "$MEMORY_USAGE" "$MEMORY_THRESHOLD" "Memory"
echo "Total Memory : ${TOTAL_MEM} MB"
echo "Used Memory  : ${USED_MEM} MB"
echo "Free Memory  : $(free -m | awk '/^Mem:/{print $4}') MB"

# ============================================================
# 4. DISK USAGE
# ============================================================
header "DISK USAGE"
df -h | grep -vE '^Filesystem|tmpfs|cdrom' | while read line; do
    USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
    MOUNT=$(echo "$line" | awk '{print $6}')
    if [ "$USAGE" -ge "$DISK_THRESHOLD" ]; then
        echo -e "${RED}[CRITICAL]${NC} $MOUNT — ${USAGE}% used"
        log "CRITICAL - Disk $MOUNT at ${USAGE}%"
    elif [ "$USAGE" -ge $((DISK_THRESHOLD - 15)) ]; then
        echo -e "${YELLOW}[WARNING] ${NC} $MOUNT — ${USAGE}% used"
    else
        echo -e "${GREEN}[OK]      ${NC} $MOUNT — ${USAGE}% used"
    fi
done

# ============================================================
# 5. SERVICE STATUS CHECK
# ============================================================
header "SERVICE STATUS"
SERVICES=("sshd" "crond" "rsyslog" "firewalld" "NetworkManager")

for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${GREEN}[RUNNING] ${NC} $service"
        log "OK       - Service $service is running"
    else
        echo -e "${RED}[STOPPED] ${NC} $service"
        log "CRITICAL - Service $service is NOT running"
    fi
done

# ============================================================
# 6. NETWORK INFO
# ============================================================
header "NETWORK INFO"
echo "IP Address   : $(hostname -I | awk '{print $1}')"
echo "Open Ports   : $(ss -tuln | grep LISTEN | wc -l) listening"
echo "Connections  : $(ss -tn | grep ESTAB | wc -l) established"

# ============================================================
# 7. SUMMARY
# ============================================================
header "HEALTH SUMMARY"
echo "Report saved to : $REPORT_FILE"
echo "Log saved to    : $LOG_FILE"
log "Health check completed for $(hostname)"

# Save report
{
    echo "=== SERVER HEALTH REPORT ==="
    echo "Host     : $(hostname)"
    echo "Date     : $(date)"
    echo "CPU      : ${CPU_USAGE}%"
    echo "Memory   : ${MEMORY_USAGE}%"
    echo "============================="
} > "$REPORT_FILE"

echo ""
echo -e "${GREEN}✅ Health check complete!${NC}"
