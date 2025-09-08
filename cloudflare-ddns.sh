#!/usr/bin/env bash
# cloudflare-ddns.sh — Update a Cloudflare DNS A record with current public IP.
# Requirements: curl, jq. Use a scoped API token with DNS edit for the zone.

set -Eeuo pipefail

CF_API_TOKEN="${CF_API_TOKEN:?Set CF_API_TOKEN}"
CF_ZONE_ID="${CF_ZONE_ID:?Set CF_ZONE_ID}"
CF_RECORD_NAME="${CF_RECORD_NAME:?Set CF_RECORD_NAME}"  # e.g., "home.example.com"
TTL="${TTL:-300}"
PROXY="${PROXY:-true}"   # orange cloud

API="https://api.cloudflare.com/client/v4"
AUTH=(-H "Authorization: Bearer ${CF_API_TOKEN}" -H "Content-Type: application/json")

current_ip() {
  curl -sS https://api.ipify.org || curl -sS https://ifconfig.me
}

PUBLIC_IP="$(current_ip)"
[[ -z "${PUBLIC_IP}" ]] && { echo "Could not determine public IP"; exit 1; }

echo "==== [cf-ddns] $(date -Is) ${CF_RECORD_NAME} -> ${PUBLIC_IP}"

# Get record ID and current content
REC_JSON="$(curl -sS -X GET "${API}/zones/${CF_ZONE_ID}/dns_records?type=A&name=${CF_RECORD_NAME}" "${AUTH[@]}")"
REC_ID="$(echo "${REC_JSON}" | jq -r '.result[0].id // empty')"
REC_IP="$(echo "${REC_JSON}" | jq -r '.result[0].content // empty')"

if [[ -n "${REC_ID}" && "${REC_IP}" == "${PUBLIC_IP}" ]]; then
  echo "[cf-ddns] No change needed (${REC_IP})"
  exit 0
fi

PAYLOAD="$(jq -nc --arg type "A" --arg name "${CF_RECORD_NAME}" --arg content "${PUBLIC_IP}" --argjson ttl ${TTL} --argjson proxied ${PROXY} '{type:$type,name:$name,content:$content,ttl:$ttl,proxied:$proxied}')"

if [[ -n "${REC_ID}" ]]; then
  echo "[cf-ddns] Updating existing record ${REC_ID}"
  curl -sS -X PUT "${API}/zones/${CF_ZONE_ID}/dns_records/${REC_ID}" "${AUTH[@]}" --data "${PAYLOAD}" | jq -r '.success'
else
  echo "[cf-ddns] Creating new record"
  curl -sS -X POST "${API}/zones/${CF_ZONE_ID}/dns_records" "${AUTH[@]}" --data "${PAYLOAD}" | jq -r '.success'
fi

echo "==== [cf-ddns] done"
# Example cron entry to run every 5 minutes:
# */5 * * * * /path/to/cloudflare-ddns.sh >> /var/log/cloudflare-ddns.log 2>&1  