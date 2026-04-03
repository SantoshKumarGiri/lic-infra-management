#!/bin/bash
# ============================================================
# Script   : incident_manager.sh
# Purpose  : Track, log, and manage IT incidents following
#            ITIL framework principles
# Author   : Santosh Kumar Giri
# Project  : LIC Linux Infrastructure Management
# ============================================================

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Config ──
DATA_DIR="./logs"
INCIDENT_DB="$DATA_DIR/incidents.csv"
REPORT_DIR="./reports"
mkdir -p "$DATA_DIR" "$REPORT_DIR"

# Initialize CSV if not exists
if [ ! -f "$INCIDENT_DB" ]; then
    echo "ID,Date,Time,Title,Priority,Category,Status,AssignedTo,ResolutionTime,Description" > "$INCIDENT_DB"
fi

# ── Helpers ──
header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   LIC INCIDENT MANAGEMENT SYSTEM            ║${NC}"
    echo -e "${CYAN}║   Infosys CIS Unit — ITIL Based Tracker     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

get_next_id() {
    local count=$(cat "$INCIDENT_DB" | wc -l)
    printf "INC%04d" "$count"
}

priority_color() {
    case "$1" in
        P1) echo -e "${RED}P1-Critical${NC}" ;;
        P2) echo -e "${YELLOW}P2-High${NC}" ;;
        P3) echo -e "${BLUE}P3-Medium${NC}" ;;
        P4) echo -e "${GREEN}P4-Low${NC}" ;;
    esac
}

# ============================================================
# MENU
# ============================================================
main_menu() {
    header
    echo -e "  ${CYAN}1.${NC} 📝 Log New Incident"
    echo -e "  ${CYAN}2.${NC} 📋 View All Incidents"
    echo -e "  ${CYAN}3.${NC} 🔍 View Open Incidents"
    echo -e "  ${CYAN}4.${NC} ✅ Resolve Incident"
    echo -e "  ${CYAN}5.${NC} 📊 Generate Incident Report"
    echo -e "  ${CYAN}6.${NC} 🚨 Demo — Auto-create Sample Incidents"
    echo -e "  ${CYAN}7.${NC} ❌ Exit"
    echo ""
    echo -n "  Select option [1-7]: "
    read choice

    case $choice in
        1) log_incident ;;
        2) view_all_incidents ;;
        3) view_open_incidents ;;
        4) resolve_incident ;;
        5) generate_report ;;
        6) demo_incidents ;;
        7) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1; main_menu ;;
    esac
}

# ============================================================
# 1. LOG NEW INCIDENT
# ============================================================
log_incident() {
    header
    echo -e "${CYAN}=== LOG NEW INCIDENT ===${NC}"
    echo ""

    local id=$(get_next_id)
    local date=$(date +%Y-%m-%d)
    local time=$(date +%H:%M:%S)

    echo -n "  Incident Title       : "
    read title

    echo "  Priority:"
    echo "    1) P1 - Critical (System Down)"
    echo "    2) P2 - High (Major Impact)"
    echo "    3) P3 - Medium (Partial Impact)"
    echo "    4) P4 - Low (Minor Issue)"
    echo -n "  Select [1-4]: "
    read p_choice
    case $p_choice in
        1) priority="P1" ;;
        2) priority="P2" ;;
        3) priority="P3" ;;
        4) priority="P4" ;;
        *) priority="P3" ;;
    esac

    echo "  Category:"
    echo "    1) Server Down    2) High CPU/Memory"
    echo "    3) Disk Full      4) Network Issue"
    echo "    5) Service Crash  6) Security Alert"
    echo -n "  Select [1-6]: "
    read c_choice
    case $c_choice in
        1) category="Server Down" ;;
        2) category="High CPU/Memory" ;;
        3) category="Disk Full" ;;
        4) category="Network Issue" ;;
        5) category="Service Crash" ;;
        6) category="Security Alert" ;;
        *) category="Other" ;;
    esac

    echo -n "  Assigned To          : "
    read assigned

    echo -n "  Description          : "
    read description

    # Save to CSV
    echo "$id,$date,$time,\"$title\",$priority,\"$category\",Open,\"$assigned\",,-\"$description\"" >> "$INCIDENT_DB"

    echo ""
    echo -e "  ${GREEN}✅ Incident logged successfully!${NC}"
    echo -e "  Incident ID : ${CYAN}$id${NC}"
    echo -e "  Priority    : $(priority_color $priority)"
    echo -e "  Status      : ${YELLOW}Open${NC}"
    echo ""
    echo -n "  Press Enter to continue..."
    read
    main_menu
}

# ============================================================
# 2. VIEW ALL INCIDENTS
# ============================================================
view_all_incidents() {
    header
    echo -e "${CYAN}=== ALL INCIDENTS ===${NC}"
    echo ""
    printf "  %-10s %-12s %-6s %-25s %-8s\n" "ID" "DATE" "PRI" "TITLE" "STATUS"
    echo "  ─────────────────────────────────────────────────────────"

    tail -n +2 "$INCIDENT_DB" | while IFS=',' read id date time title priority category status assigned res desc; do
        title_clean=$(echo "$title" | tr -d '"' | cut -c1-24)
        printf "  %-10s %-12s %-6s %-25s %-8s\n" "$id" "$date" "$priority" "$title_clean" "$status"
    done

    echo ""
    echo -n "  Press Enter to continue..."
    read
    main_menu
}

# ============================================================
# 3. VIEW OPEN INCIDENTS
# ============================================================
view_open_incidents() {
    header
    echo -e "${CYAN}=== OPEN INCIDENTS ===${NC}"
    echo ""
    local count=0
    while IFS=',' read id date time title priority category status assigned res desc; do
        if [ "$status" = "Open" ]; then
            echo -e "  ID       : ${CYAN}$id${NC}"
            echo -e "  Title    : $(echo $title | tr -d '\"')"
            echo -e "  Priority : $(priority_color $priority)"
            echo -e "  Date     : $date $time"
            echo -e "  Assigned : $(echo $assigned | tr -d '\"')"
            echo "  ─────────────────────────────"
            count=$((count+1))
        fi
    done < <(tail -n +2 "$INCIDENT_DB")

    if [ "$count" -eq 0 ]; then
        echo -e "  ${GREEN}✅ No open incidents!${NC}"
    else
        echo -e "  Total Open: ${RED}$count${NC}"
    fi

    echo ""
    echo -n "  Press Enter to continue..."
    read
    main_menu
}

# ============================================================
# 4. RESOLVE INCIDENT
# ============================================================
resolve_incident() {
    header
    echo -e "${CYAN}=== RESOLVE INCIDENT ===${NC}"
    echo ""
    echo -n "  Enter Incident ID to resolve (e.g. INC0001): "
    read inc_id

    if grep -q "^$inc_id," "$INCIDENT_DB"; then
        local res_time=$(date '+%Y-%m-%d %H:%M:%S')
        sed -i "s/^$inc_id,\(.*\),Open,/\1,Resolved,$res_time,/" "$INCIDENT_DB"
        echo -e "  ${GREEN}✅ Incident $inc_id marked as Resolved!${NC}"
        echo -e "  Resolution Time: $res_time"
    else
        echo -e "  ${RED}❌ Incident ID not found!${NC}"
    fi

    echo ""
    echo -n "  Press Enter to continue..."
    read
    main_menu
}

# ============================================================
# 5. GENERATE REPORT
# ============================================================
generate_report() {
    header
    local report="$REPORT_DIR/incident_report_$(date +%Y%m%d).txt"
    local total=$(tail -n +2 "$INCIDENT_DB" | wc -l)
    local open=$(tail -n +2 "$INCIDENT_DB" | grep -c ",Open,")
    local resolved=$(tail -n +2 "$INCIDENT_DB" | grep -c ",Resolved,")
    local p1=$(tail -n +2 "$INCIDENT_DB" | grep -c ",P1,")
    local p2=$(tail -n +2 "$INCIDENT_DB" | grep -c ",P2,")

    echo -e "${CYAN}=== INCIDENT SUMMARY REPORT ===${NC}"
    echo ""
    echo -e "  Total Incidents  : ${CYAN}$total${NC}"
    echo -e "  Open             : ${RED}$open${NC}"
    echo -e "  Resolved         : ${GREEN}$resolved${NC}"
    echo -e "  P1 Critical      : ${RED}$p1${NC}"
    echo -e "  P2 High          : ${YELLOW}$p2${NC}"
    echo ""

    {
        echo "=== LIC INCIDENT REPORT ==="
        echo "Generated : $(date)"
        echo "By        : Santosh Kumar Giri | Infosys CIS"
        echo ""
        echo "SUMMARY"
        echo "Total    : $total"
        echo "Open     : $open"
        echo "Resolved : $resolved"
        echo "P1       : $p1"
        echo "P2       : $p2"
        echo ""
        echo "ALL INCIDENTS"
        cat "$INCIDENT_DB"
    } > "$report"

    echo -e "  ${GREEN}✅ Report saved: $report${NC}"
    echo ""
    echo -n "  Press Enter to continue..."
    read
    main_menu
}

# ============================================================
# 6. DEMO — CREATE SAMPLE INCIDENTS
# ============================================================
demo_incidents() {
    header
    echo -e "${CYAN}Creating sample incidents for demo...${NC}"
    echo ""

    echo "INC0001,2025-01-15,09:23:00,\"LIC Server CPU Spike\",P1,\"High CPU/Memory\",Resolved,\"Santosh Giri\",\"2025-01-15 10:45:00\",\"CPU at 95% on prod server\"" >> "$INCIDENT_DB"
    echo "INC0002,2025-01-16,14:10:00,\"Disk Full on /var\",P2,\"Disk Full\",Resolved,\"Santosh Giri\",\"2025-01-16 15:30:00\",\"Disk 98% full — cleared old logs\"" >> "$INCIDENT_DB"
    echo "INC0003,2025-01-17,08:45:00,\"SSH Service Down\",P1,\"Service Crash\",Resolved,\"Santosh Giri\",\"2025-01-17 09:00:00\",\"sshd crashed — restarted\"" >> "$INCIDENT_DB"
    echo "INC0004,2025-01-18,11:30:00,\"Multiple Failed SSH Logins\",P2,\"Security Alert\",Open,\"Santosh Giri\",,\"Brute force attempt detected\"" >> "$INCIDENT_DB"
    echo "INC0005,2025-01-19,16:00:00,\"Network Latency High\",P3,\"Network Issue\",Open,\"Santosh Giri\",,\"Intermittent packet loss\"" >> "$INCIDENT_DB"

    echo -e "  ${GREEN}✅ 5 sample incidents created!${NC}"
    echo ""
    echo -n "  Press Enter to continue..."
    read
    main_menu
}

# ── Start ──
main_menu
