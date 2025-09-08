#!/usr/bin/env bash
# monitor.sh — Quick system health overview with logging.

set -Eeuo pipefail

LOG_DIR="${LOG_DIR:-/var/log/sysadmin-tools}"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/monitor.log"

ts() { date -Is; }

{
  echo "==== [monitor] $(ts)"
  echo "[uptime]" && uptime
  echo
  echo "[memory]" && free -h
  echo
  echo "[disk]" && df -h | awk 'NR==1 || /^\/(dev|mnt|srv)/ {print}'
  echo
  if command -v smartctl >/dev/null 2>&1; then
    echo "[smartctl] short summary (first 2 disks if present)"
    for d in /dev/sd[a-z] /dev/nvme[0-9]n1 2>/dev/null; do
      [[ -e "$d" ]] || continue
      smartctl -H "$d" | sed 's/^/  /'
    done | head -n 40
    echo
  fi
} | tee -a "${LOG_FILE}"
echo "==== [monitor] done"
# Example cron entry to run every hour:
# 0 * * * * /path/to/monitor.sh >> /var/log/monitor.log 2>&1