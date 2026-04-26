#!/usr/bin/env bash
# =============================================================================
# NetworkMemories — MGO1 Restore Script
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
source "$ROOT_DIR/.env" 2>/dev/null || true

if [ -n "${1:-}" ]; then
  BACKUP_FILE="$1"
else
  LATEST=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -n1)
  [ -z "$LATEST" ] && { echo "❌ No backup found in $BACKUP_DIR"; exit 1; }
  BACKUP_FILE="$LATEST"
fi

echo "⚠️  Will restore: $(basename "$BACKUP_FILE")"
read -rp "Type 'yes' to confirm: " CONFIRM
[ "$CONFIRM" = "yes" ] || { echo "Aborted."; exit 0; }

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

tar xzf "$BACKUP_FILE" -C "$TMPDIR"
CONTENT=$(ls "$TMPDIR")

if [ -f "$TMPDIR/$CONTENT/mgops.sql" ]; then
  echo "  → Restoring database..."
  docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T biomysql \
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" \
    < "$TMPDIR/$CONTENT/mgops.sql"
  echo "  ✅ Database restored"
fi

if [ -f "$TMPDIR/$CONTENT/dbdata.tar.gz" ]; then
  echo "  → Restoring dbdata..."
  tar xzf "$TMPDIR/$CONTENT/dbdata.tar.gz" -C "$ROOT_DIR"
  echo "  ✅ dbdata restored"
fi

echo "✅ Restore complete. Run: make run-daemon"
