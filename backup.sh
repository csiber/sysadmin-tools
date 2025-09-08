#!/usr/bin/env bash
# backup.sh — Rsync-based backup for Docker appdata/volumes.
# Logs to ${LOG_DIR}/backup.log and keeps dated snapshots.
# Optional offsite sync via rclone if RCLONE_REMOTE is set.

set -Eeuo pipefail

# --- Config (env overrides) ---
SRC_DIR="${APPDATA_SRC:-/mnt/user/appdata}"
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/user/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
LOG_DIR="${LOG_DIR:-/var/log/sysadmin-tools}"
RCLONE_REMOTE="${RCLONE_REMOTE:-}"      # e.g. "r2:homelab-backups"
RCLONE_PATH="${RCLONE_PATH:-appdata}"   # remote subpath
DRY_RUN="${DRY_RUN:-0}"                 # 1 = simulate

# --- Prep ---
TS="$(date +'%Y-%m-%d_%H-%M-%S')"
DEST_DIR="${BACKUP_ROOT}/${TS}"
mkdir -p "${DEST_DIR}" "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/backup.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "==== [backup] $(date -Is) SRC=${SRC_DIR} DEST=${DEST_DIR} DRY_RUN=${DRY_RUN}"

# --- Rsync snapshot ---
RSYNC_OPTS=(-aHAX --delete --numeric-ids --info=progress2 --stats)
# Exclude common noise; extend as needed
RSYNC_EXCLUDES=(--exclude='@eaDir' --exclude='lost+found' --exclude='*.tmp')

if [[ "${DRY_RUN}" == "1" ]]; then
  RSYNC_OPTS+=(--dry-run)
fi

rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXCLUDES[@]}" "${SRC_DIR}/" "${DEST_DIR}/"

echo "[backup] rsync finished"

# --- Retention ---
echo "[backup] pruning backups older than ${RETENTION_DAYS} days in ${BACKUP_ROOT}"
find "${BACKUP_ROOT}" -maxdepth 1 -type d -name '20*' -mtime "+${RETENTION_DAYS}" -print -exec rm -rf {} \;

# --- Optional offsite sync via rclone ---
if [[ -n "${RCLONE_REMOTE}" ]]; then
  echo "[backup] rclone syncing ${DEST_DIR} -> ${RCLONE_REMOTE}:${RCLONE_PATH}/${TS}"
  if [[ "${DRY_RUN}" == "1" ]]; then
    rclone ls "${RCLONE_REMOTE}:${RCLONE_PATH}" || true
  else
    rclone copy "${DEST_DIR}" "${RCLONE_REMOTE}:${RCLONE_PATH}/${TS}" --transfers=8 --checkers=8 --fast-list
  fi
fi

echo "==== [backup] completed $(date -Is)"
