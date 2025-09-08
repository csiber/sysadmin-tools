#!/usr/bin/env bash
# docker-cleanup.sh — Reclaim disk space safely.
# Requires --yes to actually prune; otherwise dry-run hints.

set -Eeuo pipefail

YES=0
[[ "${1:-}" == "--yes" ]] && YES=1

echo "==== [docker-cleanup] $(date -Is) YES=${YES}"
docker info >/dev/null || { echo "Docker not available"; exit 1; }

if [[ ${YES} -eq 0 ]]; then
  echo "[dry-run] Would run: docker system df"
  docker system df || true
  echo "[dry-run] Use '--yes' to prune: containers/images/networks/volumes"
  exit 0
fi

echo "[cleanup] docker system prune -af --volumes"
docker system prune -af --volumes

echo "[cleanup] dangling images check"
docker images -f "dangling=true" -q | xargs -r docker rmi

echo "[cleanup] orphaned volumes check"
docker volume ls -qf "dangling=true" | xargs -r docker volume rm

echo "==== [docker-cleanup] done $(date -Is)"
