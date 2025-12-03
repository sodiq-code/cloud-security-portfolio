#!/bin/bash

# =============================================================================
# FORENSIC SIMULATION SETUP
# =============================================================================
# This script creates a "crime scene" inside a Linux environment.
# It populates /var/log/auth.log with traces of:
# 1. SSH Brute Force attempts (Failed logins)
# 2. Successful Breach (Accepted password)
# 3. Persistence (User creation)
# 4. Privilege Escalation (Sudo abuse)
# =============================================================================

LOG_FILE="./auth.log"

echo "🚨 Setting up the victim logs at $LOG_FILE..."

# 1. Simulate NOISE (Normal traffic mixed with failed attempts)
echo "Generate Brute Force Noise..."
for i in {1..15}; do
    echo "Dec  1 08:$(printf "%02d" $i):12 ip-10-0-0-5 sshd[123$i]: Failed password for root from 192.168.1.50 port 4432$i ssh2" >> $LOG_FILE
done

# 2. Simulate THE BREACH (Attacker Guessed the password)
echo "Simulating Successful Login..."
echo "Dec  1 08:20:01 ip-10-0-0-5 sshd[1299]: Accepted password for user 'admin' from 192.168.1.50 port 5566 ssh2" >> $LOG_FILE
echo "Dec  1 08:20:01 ip-10-0-0-5 systemd-logind[455]: New session 54 of user admin." >> $LOG_FILE

# 3. Simulate PERSISTENCE (Creating a backdoor user)
echo "Simulating Backdoor Creation..."
echo "Dec  1 08:25:30 ip-10-0-0-5 useradd[1305]: new user: name=support_service, UID=0, GID=0, home=/root, shell=/bin/bash" >> $LOG_FILE
echo "Dec  1 08:25:30 ip-10-0-0-5 passwd[1306]: password changed for support_service" >> $LOG_FILE

# 4. Simulate DATA THEFT (Using sudo)
echo "Simulating Data Exfiltration..."
echo "Dec  1 08:30:15 ip-10-0-0-5 sudo:    admin : TTY=pts/0 ; PWD=/home/admin ; USER=root ; COMMAND=/bin/tar -czf /tmp/data_dump.tar.gz /var/www/html" >> $LOG_FILE

echo "✅ Crime Scene Ready. Analyze '$LOG_FILE' to find the attacker."