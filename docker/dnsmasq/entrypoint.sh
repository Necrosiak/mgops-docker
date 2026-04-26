#!/bin/sh
# Generates dnsmasq config from environment variables, then starts dnsmasq.
set -e

: "${SERVER_IP:?SERVER_IP is required}"

cat > /etc/dnsmasq.conf <<EOF
# NetworkMemories — MGO1 DNS
# Auto-generated from environment — do not edit manually.

no-resolv
no-hosts
keep-in-foreground
log-queries

# Wildcard: route all *.konamionline.com to the MGO1 server
address=/konamionline.com/${SERVER_IP}

# Fallback DNS (Google) for everything else
server=8.8.8.8
server=8.8.4.4
EOF

echo "[dns] Resolving *.konamionline.com → ${SERVER_IP}"
exec dnsmasq
