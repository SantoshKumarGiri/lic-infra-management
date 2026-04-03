#!/bin/bash
# ============================================================
# Script   : system_hardening.sh
# Purpose  : Check and apply Linux system hardening based
#            on CIS Benchmark and ITIL security standards
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
REPORT_DIR="./reports"
LOG_DIR="./logs"
mkdir -p "$REPORT_DIR" "$LOG_DIR"
REPORT="$REPORT_DIR/hardening_report_$(date +%Y%m%d_%H%M%S).txt"
LOG="$LOG_DIR/hardening.log"

PASS=0
FAIL=0
WARN=0

# ── Helpers ──
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG"; }

check_pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    log "PASS - $1"
    PASS=$((PASS+1))
}

check_fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    log "FAIL - $1"
    FAIL=$((FAIL+1))
}

check_warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
    log "WARN - $1"
    WARN=$((WARN+1))
}

header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  LIC SYSTEM HARDENING CHECKER           ║${NC}"
echo -e "${CYAN}║  CIS Benchmark + ITIL Security Standard ║${NC}"
echo -e "${CYAN}║  Santosh Kumar Giri — Infosys CIS       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
log "System hardening check started on $(hostname)"

# ============================================================
# 1. USER & PASSWORD POLICY
# ============================================================
header "1. USER & PASSWORD POLICY"

# Check if root login is disabled
if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
    check_pass "Root SSH login is disabled"
else
    check_fail "Root SSH login should be disabled — set PermitRootLogin no"
fi

# Check password minimum length
MIN_LEN=$(grep "^PASS_MIN_LEN" /etc/login.defs 2>/dev/null | awk '{print $2}')
if [ -n "$MIN_LEN" ] && [ "$MIN_LEN" -ge 12 ]; then
    check_pass "Password minimum length is $MIN_LEN (>=12)"
else
    check_warn "Password minimum length is ${MIN_LEN:-not set} — recommend 12+"
fi

# Check password max days
MAX_DAYS=$(grep "^PASS_MAX_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
if [ -n "$MAX_DAYS" ] && [ "$MAX_DAYS" -le 90 ]; then
    check_pass "Password max age is $MAX_DAYS days (<=90)"
else
    check_warn "Password max age is ${MAX_DAYS:-not set} — recommend 90 days"
fi

# Check if password complexity is enabled
if [ -f /etc/security/pwquality.conf ]; then
    check_pass "Password quality module (pwquality) is present"
else
    check_fail "Password quality module not configured"
fi

# Check for empty password accounts
EMPTY_PASS=$(awk -F: '($2 == "" ) { print $1}' /etc/shadow 2>/dev/null | wc -l)
if [ "$EMPTY_PASS" -eq 0 ]; then
    check_pass "No accounts with empty passwords"
else
    check_fail "$EMPTY_PASS account(s) have empty passwords"
fi

# ============================================================
# 2. SSH CONFIGURATION
# ============================================================
header "2. SSH CONFIGURATION"

SSH_CONFIG="/etc/ssh/sshd_config"

# Protocol version
if grep -q "^Protocol 2" "$SSH_CONFIG" 2>/dev/null; then
    check_pass "SSH Protocol 2 is enforced"
else
    check_warn "SSH Protocol version not explicitly set — recommend Protocol 2"
fi

# SSH Port
SSH_PORT=$(grep "^Port " "$SSH_CONFIG" 2>/dev/null | awk '{print $2}')
if [ -n "$SSH_PORT" ] && [ "$SSH_PORT" != "22" ]; then
    check_pass "SSH running on non-default port: $SSH_PORT"
else
    check_warn "SSH running on default port 22 — consider changing"
fi

# X11 Forwarding
if grep -q "^X11Forwarding no" "$SSH_CONFIG" 2>/dev/null; then
    check_pass "X11 Forwarding is disabled"
else
    check_warn "X11 Forwarding not explicitly disabled"
fi

# Max Auth Tries
MAX_TRIES=$(grep "^MaxAuthTries" "$SSH_CONFIG" 2>/dev/null | awk '{print $2}')
if [ -n "$MAX_TRIES" ] && [ "$MAX_TRIES" -le 4 ]; then
    check_pass "MaxAuthTries is $MAX_TRIES (<=4)"
else
    check_warn "MaxAuthTries is ${MAX_TRIES:-not set} — recommend 4 or less"
fi

# ============================================================
# 3. FIREWALL STATUS
# ============================================================
header "3. FIREWALL STATUS"

if systemctl is-active --quiet firewalld 2>/dev/null; then
    check_pass "firewalld is active and running"
elif systemctl is-active --quiet iptables 2>/dev/null; then
    check_pass "iptables is active and running"
elif systemctl is-active --quiet ufw 2>/dev/null; then
    check_pass "ufw is active and running"
else
    check_fail "No active firewall detected — CRITICAL!"
fi

# ============================================================
# 4. FILE PERMISSIONS
# ============================================================
header "4. CRITICAL FILE PERMISSIONS"

# /etc/passwd
PASSWD_PERM=$(stat -c "%a" /etc/passwd 2>/dev/null)
if [ "$PASSWD_PERM" = "644" ]; then
    check_pass "/etc/passwd permissions are 644"
else
    check_fail "/etc/passwd permissions are $PASSWD_PERM — should be 644"
fi

# /etc/shadow
SHADOW_PERM=$(stat -c "%a" /etc/shadow 2>/dev/null)
if [ "$SHADOW_PERM" = "000" ] || [ "$SHADOW_PERM" = "640" ]; then
    check_pass "/etc/shadow permissions are $SHADOW_PERM (restricted)"
else
    check_warn "/etc/shadow permissions are $SHADOW_PERM — should be 000 or 640"
fi

# /etc/ssh/sshd_config
if [ -f "$SSH_CONFIG" ]; then
    SSH_PERM=$(stat -c "%a" "$SSH_CONFIG" 2>/dev/null)
    if [ "$SSH_PERM" = "600" ]; then
        check_pass "sshd_config permissions are 600"
    else
        check_warn "sshd_config permissions are $SSH_PERM — should be 600"
    fi
fi

# ============================================================
# 5. RUNNING SERVICES AUDIT
# ============================================================
header "5. UNNECESSARY SERVICES AUDIT"

UNNECESSARY=("telnet" "rsh" "rlogin" "tftp" "ftp" "sendmail" "cups")
for svc in "${UNNECESSARY[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        check_fail "Insecure service '$svc' is running — should be disabled"
    else
        check_pass "Insecure service '$svc' is not running"
    fi
done

# ============================================================
# 6. SYSTEM UPDATES
# ============================================================
header "6. SYSTEM UPDATE STATUS"

if command -v yum &>/dev/null; then
    UPDATES=$(yum check-update --quiet 2>/dev/null | grep -v "^$" | wc -l)
    if [ "$UPDATES" -eq 0 ]; then
        check_pass "System is up to date (yum)"
    else
        check_warn "$UPDATES package update(s) available"
    fi
elif command -v apt &>/dev/null; then
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    if [ "$UPDATES" -eq 0 ]; then
        check_pass "System is up to date (apt)"
    else
        check_warn "$UPDATES package update(s) available"
    fi
else
    check_warn "Package manager not detected — check updates manually"
fi

# ============================================================
# FINAL SCORE
# ============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  HARDENING SCORE SUMMARY${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
TOTAL=$((PASS+FAIL+WARN))
SCORE=$(awk "BEGIN {printf \"%d\", ($PASS/$TOTAL)*100}")
echo -e "  ${GREEN}PASS   : $PASS${NC}"
echo -e "  ${RED}FAIL   : $FAIL${NC}"
echo -e "  ${YELLOW}WARN   : $WARN${NC}"
echo -e "  Total  : $TOTAL checks"
echo ""
if [ "$SCORE" -ge 80 ]; then
    echo -e "  Security Score : ${GREEN}${SCORE}% — GOOD${NC}"
elif [ "$SCORE" -ge 60 ]; then
    echo -e "  Security Score : ${YELLOW}${SCORE}% — NEEDS IMPROVEMENT${NC}"
else
    echo -e "  Security Score : ${RED}${SCORE}% — CRITICAL${NC}"
fi

# Save report
{
    echo "=== HARDENING REPORT ==="
    echo "Host   : $(hostname)"
    echo "Date   : $(date)"
    echo "By     : Santosh Kumar Giri | Infosys CIS"
    echo "Score  : ${SCORE}%"
    echo "Pass   : $PASS | Fail: $FAIL | Warn: $WARN"
} > "$REPORT"

echo ""
echo "  Report saved: $REPORT"
log "Hardening check complete — Score: ${SCORE}%"
echo -e "  ${GREEN}✅ Hardening check complete!${NC}"
