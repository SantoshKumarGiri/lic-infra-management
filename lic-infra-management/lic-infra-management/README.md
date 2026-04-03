# 🏦 LIC Linux Infrastructure Management
### Infosys CIS Unit — System Engineer Project

![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![RHEL](https://img.shields.io/badge/RHEL-EE0000?style=for-the-badge&logo=redhat&logoColor=white)
![ITIL](https://img.shields.io/badge/ITIL-Framework-blue?style=for-the-badge)

> **Real-world project** simulating Linux infrastructure management for LIC (Life Insurance Corporation of India) at Infosys CIS Unit — covering server monitoring, log analysis, incident management, and system hardening.

---

## 📋 Project Overview

As a **System Engineer** in the **CIS Unit at Infosys**, I manage the Linux (RHEL) infrastructure for the **LIC Infra Team**. This project contains the automation scripts I use for:

- 📊 **Server Health Monitoring** — CPU, Memory, Disk, Services
- 🔍 **Log Analysis** — Error detection, failed logins, suspicious activity
- 🎫 **Incident Management** — ITIL-based incident tracker
- 🔒 **System Hardening** — CIS Benchmark security checks

---

## 📁 Project Structure

```
lic-infra-management/
│
├── scripts/
│   ├── server_health_monitor.sh   # Monitor CPU, Memory, Disk, Services
│   ├── log_analysis.sh            # Analyze system & auth logs
│   ├── incident_manager.sh        # ITIL-based incident tracker
│   └── system_hardening.sh        # CIS security hardening checks
│
├── logs/                          # Auto-generated log files
│   ├── monitor.log
│   ├── incidents.csv
│   └── hardening.log
│
├── reports/                       # Auto-generated reports
│   ├── health_report_<date>.txt
│   ├── log_analysis_<date>.txt
│   ├── incident_report_<date>.txt
│   └── hardening_report_<date>.txt
│
└── README.md
```

---

## 🚀 How to Use

### Prerequisites
- Linux / RHEL / CentOS / Ubuntu
- Bash shell
- Root or sudo access (for full functionality)

### Setup
```bash
# Clone the repository
git clone https://github.com/SantoshKumarGiri/lic-infra-management.git
cd lic-infra-management

# Give execute permissions to all scripts
chmod +x scripts/*.sh
```

---

## 📊 Script 1 — Server Health Monitor

Checks CPU, memory, disk usage and service status with color-coded alerts.

```bash
./scripts/server_health_monitor.sh
```

**What it checks:**
| Check | Threshold | Action |
|---|---|---|
| CPU Usage | >80% | 🔴 CRITICAL alert |
| Memory Usage | >80% | 🔴 CRITICAL alert |
| Disk Usage | >85% | 🔴 CRITICAL alert |
| Key Services | Down | 🔴 CRITICAL alert |

**Sample Output:**
```
========================================
  CPU USAGE
========================================
[OK]       CPU: 23% (Threshold: 80%)
Load Average : 0.15 0.10 0.08

========================================
  MEMORY USAGE
========================================
[WARNING]  Memory: 72% (Threshold: 80%)
Total Memory : 8192 MB
Used Memory  : 5898 MB
```

---

## 🔍 Script 2 — Log Analysis

Scans system logs for errors, failed logins, and suspicious activity.

```bash
./scripts/log_analysis.sh
```

**What it analyzes:**
- `/var/log/messages` — System errors and warnings
- `/var/log/secure` — Failed SSH logins and auth events
- `dmesg` — Kernel and disk errors
- `/var/log/cron` — Cron job failures

**Sample Output:**
```
========================================
  FAILED LOGIN ATTEMPTS
========================================
Failed password attempts : 12
Invalid user attempts    : 4
[ALERT] High number of failed logins detected!

--- Top Source IPs (Failed Logins) ---
   8  192.168.1.105
   3  10.0.0.22
```

---

## 🎫 Script 3 — Incident Manager (ITIL Based)

Interactive incident tracker following ITIL framework for incident management.

```bash
./scripts/incident_manager.sh
```

**Features:**
- Log new incidents with Priority (P1/P2/P3/P4)
- View all open incidents
- Resolve incidents with timestamp
- Generate summary reports
- Demo mode with sample incidents

**Priority Levels (ITIL):**
| Priority | Level | Response Time |
|---|---|---|
| P1 | Critical — System Down | Immediate |
| P2 | High — Major Impact | 1 hour |
| P3 | Medium — Partial Impact | 4 hours |
| P4 | Low — Minor Issue | 24 hours |

**Sample Incident Log:**
```
INC0001 | 2025-01-15 | P1 | LIC Server CPU Spike    | Resolved
INC0002 | 2025-01-16 | P2 | Disk Full on /var        | Resolved
INC0003 | 2025-01-17 | P1 | SSH Service Down         | Resolved
INC0004 | 2025-01-18 | P2 | Multiple Failed Logins   | Open
```

---

## 🔒 Script 4 — System Hardening Checker

Audits server security against CIS Benchmark standards.

```bash
# Run as root for full results
sudo ./scripts/system_hardening.sh
```

**Checks Performed:**
- ✅ Password policy (min length, max age, complexity)
- ✅ SSH configuration (root login, protocol, port)
- ✅ Firewall status (firewalld/iptables)
- ✅ Critical file permissions (/etc/passwd, /etc/shadow)
- ✅ Unnecessary/insecure services (telnet, ftp, rsh)
- ✅ System update status

**Sample Score:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  HARDENING SCORE SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PASS   : 14
  FAIL   : 2
  WARN   : 3
  Security Score : 74% — NEEDS IMPROVEMENT
```

---

## 🛠️ Technologies Used

| Tool | Purpose |
|---|---|
| **Bash Shell** | All automation scripts |
| **RHEL / Linux** | Target operating system |
| **systemctl** | Service management |
| **awk / grep / sed** | Log parsing and text processing |
| **df / free / top** | System resource monitoring |
| **ss / netstat** | Network monitoring |
| **ITIL Framework** | Incident management methodology |
| **CIS Benchmark** | Security hardening standard |

---

## 📈 Real-World Application

These scripts simulate the actual work done as a **System Engineer at Infosys CIS Unit** for **LIC (Life Insurance Corporation of India)**:

- 🖥️ Monitoring RHEL servers to maintain **99%+ uptime**
- 📋 Managing incidents following **ITIL** principles
- 🔒 Applying **CIS Benchmark** security hardening
- 📝 Generating reports for **SLA compliance**

---

## 👨‍💻 Author

**Santosh Kumar Giri**
System Engineer → DevOps Engineer (In Transition)
Infosys Limited — CIS Unit | LIC Infra Team

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://linkedin.com/in/santosh-kumar-giri-955609142)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=flat&logo=github&logoColor=white)](https://github.com/SantoshKumarGiri)
[![Portfolio](https://img.shields.io/badge/Portfolio-00e5ff?style=flat&logo=googlechrome&logoColor=black)](https://santoshkumargiri.github.io)
[![Medium](https://img.shields.io/badge/Medium-12100E?style=flat&logo=medium&logoColor=white)](https://medium.com/@santoshraj.nic)

---

> ⭐ Star this repo if you find it useful!
