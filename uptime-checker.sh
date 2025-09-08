#!/usr/bin/env bash
# uptime-checker.sh — Simple HTTP/HTTPS health checks with logging and webhook alerts.

set -Eeuo pipefail

TARGETS_FILE="${TARGETS_FILE:-./services.txt}"   # one URL per line
TIMEOUT="${TIMEOUT:-7}"
LOG_DIR="${LOG_DIR:-/var/log/sysadmin-tools}"
WEBHOOK_URL="${WEBHOOK_URL:-}"                   # optional (e.g., Discord)

mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/uptime.log"

ts() { date -Is; }

notify() {
  local msg="$1"
  [[ -z "${WEBHOOK_URL}" ]] && return 0
  curl -sS -X POST -H "Content-Type: application/json" \
    -d "$(jq -nc --arg c "${msg}" '{content:$c}')" "${WEBHOOK_URL}" >/dev/null || true
}

[[ -f "${TARGETS_FILE}" ]] || { echo "Targets file not found: ${TARGETS_FILE}"; exit 1; }

while IFS= read -r url; do
  [[ -z "${url}" || "${url}" =~ ^# ]] && continue
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time "${TIMEOUT}" "${url}" || echo "000")
  if [[ "${code}" =~ ^2|3 ]]; then
    echo "$(ts) OK ${code} ${url}" | tee -a "${LOG_FILE}"
  else
    line="$(ts) DOWN ${code} ${url}"
    echo "${line}" | tee -a "${LOG_FILE}"
    notify ":rotating_light: ${line}"
  fi
done < "${TARGETS_FILE}"
