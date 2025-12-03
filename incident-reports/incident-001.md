# 🚨 Incident Report: IR-2025-001

**Date:** [Dec-01-2025]
**Analyst:** [Sodiq Bolaji]
**Severity:** CRITICAL
**Status:** CLOSED

## 1. Executive Summary
On Dec 1st, a Brute Force attack was detected against the `admin` account. The attacker successfully compromised the account, escalated privileges, created a backdoor user (`support_service`), and exfiltrated data (`data_dump.tar.gz`).

## 2. Timeline of Events
| Timestamp | Event Type | Description |
| :--- | :--- | :--- |
| **08:00 - 08:15** | Attempted Intrusion | Multiple failed SSH login attempts from IP `192.168.1.50`. |
| **08:20:01** | **Compromise** | Successful login to user `admin` from malicious IP. |
| **08:25:30** | Persistence | Attacker created a backdoor user named `support_service` with UID 0 (Root). |
| **08:30:15** | Data Exfiltration | Attacker used `sudo` to compress website data into `/tmp/data_dump.tar.gz`. |

## 3. Indicators of Compromise (IOCs)
* **Attacker IP:** `192.168.1.50`
* **Compromised Account:** `admin`
* **Malicious User Created:** `support_service`

## 4. Remediation Actions Taken
1.  Blocked IP `192.168.1.50` in Network ACL (using Week 9 Python script).
2.  Locked `admin` account and forced password reset.
3.  Deleted malicious user `support_service`.
4.  Isolated host for further forensic analysis.

## 5. Evidence
![Forensic Logs](../docs/week10/screenshots/forensics-evidence.png)