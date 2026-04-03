#!/bin/bash
# ============================================================
# Script   : log_analysis.sh
# Purpose  : Analyze system logs for errors, warnings,
#            failed logins, and suspicious activity
# Author   : Santosh Kumar Giri
# Project  : LIC Linux Infrastructure Management
# ============================================================

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Config ──
LOG_DIR="./logs"
REPORT_DIR="./reports"
mkdir -p "$LOG_DIR" "$REPORT_DIR"

ANALYSIS_REPORT="$REPORT_DIR/log_analysis_$(date +%Y%m%d_%H%M%S).txt"
SCRIPT_LOG="$LOG_DIR/log_analysis.log"

# System log files to analyze
SYSLOG="/var/log/messages"
AUTH_LOG="/var/log/secure"
KERN_LOG="/var/log/kern.log"

# Fallback for non-RHEL systems
[ ! -f "$SYSLOG" ]   && SYSLOG="/var/log/syslog"
[ ! -f "$AUTH_LOG" ] && AUTH_LOG="/var/log/auth.log"

# ── Helper ──
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$SCRIPT_LOG"; }
header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   LIC LOG ANALYSIS TOOL              ║${NC}"
echo -e "${CYAN}║   Santosh Kumar Giri — Infosys CIS   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""
log "Log analysis started"

# ============================================================
# 1. SYSTEM ERROR ANALYSIS
# ============================================================
header "SYSTEM ERRORS (Last 100 lines)"
if [ -f "$SYSLOG" ]; then
    ERROR_COUNT=$(tail -100 "$SYSLOG" | grep -ci "error\|critical\|failed\|fatal" 2>/dev/null || echo 0)
    WARN_COUNT=$(tail -100 "$SYSLOG"  | grep -ci "warning\|warn" 2>/dev/null || echo 0)

    echo -e "Errors found   : ${RED}$ERROR_COUNT${NC}"
    echo -e "Warnings found : ${YELLOW}$WARN_COUNT${NC}"

    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo ""
        echo "--- Recent Errors ---"
        tail -100 "$SYSLOG" | grep -i "error\|critical\|fatal" | tail -5
    fi
    log "System log: $ERROR_COUNT errors, $WARN_COUNT warnings"
else
    echo -e "${YELLOW}[SKIP]${NC} System log not accessible (requires root)"
    echo "       Simulating log analysis for demo purposes..."
    echo -e "Errors found   : ${RED}3${NC} (simulated)"
    echo -e "Warnings found : ${YELLOW}7${NC} (simulated)"
    log "System log not accessible — demo mode"
fi

# ============================================================
# 2. FAILED LOGIN ATTEMPTS
# ============================================================
header "FAILED LOGIN ATTEMPTS"
if [ -f "$AUTH_LOG" ]; then
    FAILED_LOGINS=$(grep -c "Failed password" "$AUTH_LOG" 2>/dev/null || echo 0)
    INVALID_USERS=$(grep -c "Invalid user" "$AUTH_LOG" 2>/dev/null || echo 0)

    echo -e "Failed password attempts : ${RED}$FAILED_LOGINS${NC}"
    echo -e "Invalid user attempts    : ${RED}$INVALID_USERS${NC}"

    if [ "$FAILED_LOGINS" -gt 5 ]; then
        echo -e "${RED}[ALERT]${NC} High number of failed logins detected!"
        log "ALERT - $FAILED_LOGINS failed login attempts"
    fi

    # Top attacking IPs
    echo ""
    echo "--- Top Source IPs (Failed Logins) ---"
    grep "Failed password" "$AUTH_LOG" 2>/dev/null | \
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
        sort | uniq -c | sort -rn | head -5 || echo "No data available"
else
    echo -e "${YELLOW}[SKIP]${NC} Auth log not accessible (requires root)"
    echo "       Demo: Simulating auth log analysis..."
    echo -e "Failed password attempts : ${RED}12${NC} (simulated)"
    echo -e "Invalid user attempts    : ${RED}4${NC} (simulated)"
    log "Auth log not accessible — demo mode"
fi

# ============================================================
# 3. DISK & KERNEL ERRORS
# ============================================================
header "DISK & KERNEL ERRORS"
if [ -f "$KERN_LOG" ]; then
    DISK_ERRORS=$(grep -ci "I/O error\|disk error\|bad sector" "$KERN_LOG" 2>/dev/null || echo 0)
    echo -e "Disk I/O errors : ${RED}$DISK_ERRORS${NC}"
    log "Disk errors: $DISK_ERRORS"
else
    # Use dmesg as fallback
    DISK_ERRORS=$(dmesg 2>/dev/null | grep -ci "I/O error\|disk error" || echo 0)
    echo -e "Disk I/O errors (dmesg) : ${RED}$DISK_ERRORS${NC}"
fi

# OOM Killer events
OOM_EVENTS=$(dmesg 2>/dev/null | grep -c "Out of memory\|OOM" || echo 0)
if [ "$OOM_EVENTS" -gt 0 ]; then
    echo -e "${RED}[ALERT]${NC} OOM Killer events detected: $OOM_EVENTS"
    log "ALERT - OOM events: $OOM_EVENTS"
else
    echo -e "${GREEN}[OK]${NC} No OOM Killer events"
fi

# ============================================================
# 4. LAST LOGINS SUMMARY
# ============================================================
header "RECENT LOGIN ACTIVITY"
echo "Last 5 logins:"
last 2>/dev/null | head -5 || echo "last command not available"
echo ""
echo "Currently logged in:"
who 2>/dev/null || echo "No users currently logged in"

# ============================================================
# 5. CRON JOB ERRORS
# ============================================================
header "CRON JOB STATUS"
CRON_LOG="/var/log/cron"
if [ -f "$CRON_LOG" ]; then
    CRON_ERRORS=$(grep -c "ERROR\|FAILED" "$CRON_LOG" 2>/dev/null || echo 0)
    echo -e "Cron errors : ${RED}$CRON_ERRORS${NC}"
else
    echo -e "${YELLOW}[SKIP]${NC} Cron log not accessible"
fi
echo "Scheduled cron jobs:"
crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" || echo "No cron jobs for current user"

# ============================================================
# 6. SAVE REPORT
# ============================================================
header "ANALYSIS COMPLETE"
{
    echo "=== LOG ANALYSIS REPORT ==="
    echo "Host   : $(hostname)"
    echo "Date   : $(date)"
    echo "By     : Santosh Kumar Giri | Infosys CIS"
    echo "==========================="
} > "$ANALYSIS_REPORT"

echo "Report saved : $ANALYSIS_REPORT"
log "Log analysis completed"
echo -e "${GREEN}✅ Log analysis complete!${NC}"
