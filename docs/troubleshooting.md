# Troubleshooting — MGO1

## PS2 stuck at "Connecting..." / DNS not resolving

1. Verify port 53 is free on the host:
   ```bash
   sudo ss -tulnp | grep :53
   ```
2. If `systemd-resolved` holds it: `make disable-systemd-resolved`
3. Test DNS from another machine:
   ```bash
   nslookup mgo.konamionline.com YOUR_SERVER_IP
   # Expected: address = YOUR_SERVER_IP
   ```
4. Check DNS container: `make logs-dns`

---

## PS2 connects but login fails

1. Check the gateway container: `make logs-gateway`
2. Ensure `FORCE_DEV_LOGIN` is NOT set to true in production
3. Try creating an account via the PS2 menu — check Apache logs:
   ```bash
   docker logs mgops-gateway
   ```
4. Verify the PHP endpoint receives the POST:
   - The PS2 must reach `http://YOUR_SERVER_IP/us/mgs3/reguser/reguser.html`

---

## Java server won't start — MySQL connection refused

1. Check MySQL is healthy:
   ```bash
   docker ps | grep mgops-mysql
   make logs
   ```
2. Wait ~15s after `make run-daemon` — MySQL needs time to initialize on first boot
3. Verify `.env` credentials match what MySQL was initialized with
4. If credentials were changed after first run, wipe the volume:
   ```bash
   make backup
   make down-volumes
   make run-daemon
   ```

---

## `Operation not allowed for a forward only resultset`

This is the MySQL 8 ResultSet issue. Apply **Patch 1** from `docs/java-patches.md`
to all files that call `createStatement()`.

---

## `Unknown column 'rank' in field list`

Apply **Patch 2** from `docs/java-patches.md` — escape all `rank` column
references with backticks.

---

## Port 5731-5735 not reachable from PS2

If your server is behind a router/NAT, add port forwarding rules:
- TCP/UDP 5731–5735 → server internal IP
- TCP/UDP 53 → server internal IP
- TCP 80, 443 → server internal IP

---

## Admin panel: blank page or DB error

1. `docker logs mgops-gateway` for PHP errors
2. Verify `MYSQL_HOST=biomysql` in `.env` (must match the service name in compose)
3. Ensure the DB is initialized: `make shell-db` → `SHOW TABLES;`
