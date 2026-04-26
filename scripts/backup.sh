#!/usr/bin/env bash
# =============================================================================
# NetworkMemories — MGO1 Backup Script
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/mgops_$DATE"

source "$ROOT_DIR/.env" 2>/dev/null || true
mkdir -p "$BACKUP_PATH"

echo "📦 Starting MGO1 backup → $BACKUP_PATH"

echo "  → Dumping database..."
docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T biomysql \
  mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" \
  > "$BACKUP_PATH/mgops.sql"
echo "  ✅ Database dumped"

if [ -d "$ROOT_DIR/dbdata" ]; then
  echo "  → Compressing dbdata..."
  tar czf "$BACKUP_PATH/dbdata.tar.gz" -C "$ROOT_DIR" dbdata
  echo "  ✅ dbdata compressed"
fi

tar czf "$BACKUP_DIR/mgops_$DATE.tar.gz" -C "$BACKUP_DIR" "mgops_$DATE"
rm -rf "$BACKUP_PATH"

echo "✅ Backup: $BACKUP_DIR/mgops_$DATE.tar.gz"
ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true
echo "🧹 Old backups pruned (keeping last 7)"
