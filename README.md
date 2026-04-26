# Metal Gear Online 1 — Docker Server

> **NetworkMemories** fork of [curi0us/mgops](https://github.com/curi0us/mgops)  
> Fully dockerized revival server for **Metal Gear Online 1** (MGS3: Subsistence Online, PS2)

---

## What's new in this fork

- ✅ Full Docker setup — zero manual Java installs
- ✅ All config via `.env` — no hardcoded IPs, ports, or credentials
- ✅ MySQL 8 compatible (4 patches applied — see `docs/java-patches.md`)
- ✅ Integrated DNS container (resolves `*.konamionline.com` → your server)
- ✅ PHP gateway with account management endpoints (reguser / deluser / chgpswd)
- ✅ Admin panel at `/admin` (player list, kick/ban, server status)
- ✅ Backup & restore scripts
- ✅ Password algorithm fully documented (`docs/password-algorithm.md`)

---

## Requirements

- Docker ≥ 24 + Docker Compose v2
- A Linux server (or WSL2 on Windows) with a public IP
- PS2 with network adapter + MGS3: Subsistence disc  
  **or** PCSX2/RPCS3 emulator

---

## Quick Start

```bash
# 1. Clone your fork
git clone https://github.com/NetworkMemories/mgops-docker.git
cd mgops-docker

# 2. Initialize
make init
# → Creates .env from .env.example

# 3. Edit .env — required fields:
#    SERVER_IP, MYSQL_ROOT_PASSWORD, MYSQL_PASSWORD, ADMIN_PASSWORD
nano .env

# 4. Build all containers
make build

# 5. (Linux) Free port 53 before starting DNS
make disable-systemd-resolved

# 6. Start everything
make run-daemon

# 7. Configure PS2/emulator DNS → SERVER_IP
```

---

## Key `.env` Variables

| Variable | Description | Default |
|---|---|---|
| `SERVER_IP` | Your public server IP | **required** |
| `MYSQL_ROOT_PASSWORD` | MySQL root password | **required** |
| `MYSQL_PASSWORD` | App DB password | **required** |
| `ADMIN_PASSWORD` | Admin panel password | **required** |
| `MGO1_PORT_AUTH` | External auth port (PS2 connects here) | `5731` |
| `MGO1_PORT_LOBBY` | External lobby port | `5732` |
| `LOG_LEVEL` | DEBUG / INFO / WARN / ERROR | `INFO` |

Full list in `.env.example`.

---

## Port Reference

| Port (external) | Port (internal Java) | Purpose |
|---|---|---|
| 5731 | 6731 | Auth server |
| 5732 | 6732 | Lobby server |
| 5733 | 6733 | Game server 1 |
| 5734 | 6734 | Game server 2 |
| 5735 | 6735 | Game server 3 |
| 53 | 53 | DNS (UDP+TCP) |
| 80 | 80 | Web gateway (HTTP) |
| 443 | 443 | Web gateway (HTTPS) |

> The internal offset (+1000) avoids conflicts with other services on the host.  
> Docker handles the external→internal mapping transparently.

---

## PS2 Network Setup

1. Go to **PS2 Network Configuration**
2. Set **Primary DNS** → `YOUR_SERVER_IP`
3. Set **Secondary DNS** → your router/gateway IP
4. Save and test connection

The DNS container will resolve `*.konamionline.com` to your server automatically.

---

## Account Management

The PHP gateway handles three PS2-initiated endpoints:

| PS2 Action | Endpoint |
|---|---|
| Create account | `POST /us/mgs3/reguser/reguser.html` |
| Delete account | `POST /us/mgs3/deluser/deluser.html` |
| Change password | `POST /us/mgs3/chgpswd/chgpswd.html` |

See `docs/password-algorithm.md` for the full MD5 + fixed-salt scheme.

---

## Admin Panel

Navigate to `http://YOUR_SERVER_IP/admin`  
Login: `ADMIN_USER` / `ADMIN_PASSWORD` from your `.env`

Features: player list, kick, ban, unban, delete, server status.

---

## `make` Commands

```
make help                    List all commands
make init                    First-time setup
make build                   Build all Docker images
make run-daemon              Start all services (background)
make stop                    Stop services
make logs                    Follow all logs
make logs-server             MGO1 Java server logs only
make shell-db                MySQL shell
make backup                  Backup DB + data
make restore                 Restore latest backup
make disable-systemd-resolved  Free port 53 (Linux)
make enable-systemd-resolved   Restore port 53 after shutdown
```

---

## Java Patches Applied

See [`docs/java-patches.md`](docs/java-patches.md) for the 6 patches over the
original source:
1. MySQL 8 `TYPE_SCROLL_INSENSITIVE` ResultSets
2. Backtick-escaped `` `rank` `` column
3. ThreadLocal lobbyId (thread-safety)
4. Bind to `0.0.0.0` (Docker network visibility)
5. Port config via JVM system properties
6. DB credentials via JVM system properties

---

## Troubleshooting

See [`docs/troubleshooting.md`](docs/troubleshooting.md)

---

## Credits

- Original server: [curi0us/mgops](https://github.com/curi0us/mgops)
- SaveMGO community: [savemgo.com](https://savemgo.com)
- This fork: [NetworkMemories](https://network-memories.com)

## License

GPL-3.0 (inherited from original project)
