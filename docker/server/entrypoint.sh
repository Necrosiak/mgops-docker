#!/bin/sh
# =============================================================================
# NetworkMemories — MGO1 Server Entrypoint
# Injects environment variables as JVM system properties
# =============================================================================
set -e

echo "[mgops] Starting Metal Gear Online 1 server..."
echo "[mgops] Server IP  : ${SERVER_IP}"
echo "[mgops] DB Host    : ${MYSQL_HOST}:${MYSQL_PORT}"
echo "[mgops] DB Name    : ${MYSQL_DATABASE}"
echo "[mgops] Auth port  : ${MGO1_INTERNAL_AUTH:-6731}"
echo "[mgops] Lobby port : ${MGO1_INTERNAL_LOBBY:-6732}"

exec java \
  -cp "classes:lib/*" \
  -Dserver.ip="${SERVER_IP}" \
  -Ddb.host="${MYSQL_HOST:-biomysql}" \
  -Ddb.port="${MYSQL_PORT:-3306}" \
  -Ddb.name="${MYSQL_DATABASE:-mgops}" \
  -Ddb.user="${MYSQL_USER}" \
  -Ddb.password="${MYSQL_PASSWORD}" \
  -Dserver.port.auth="${MGO1_INTERNAL_AUTH:-6731}" \
  -Dserver.port.lobby="${MGO1_INTERNAL_LOBBY:-6732}" \
  -Dserver.port.game1="${MGO1_INTERNAL_GAME1:-6733}" \
  -Dserver.port.game2="${MGO1_INTERNAL_GAME2:-6734}" \
  -Dserver.port.game3="${MGO1_INTERNAL_GAME3:-6735}" \
  -Dlog.level="${LOG_LEVEL:-INFO}" \
  com.savemgo.mgo1.Main "$@"
