# Java Source Patches

This document describes all patches applied to the original `curi0us/mgops`
Java source code to make it work with modern MySQL 8 and Docker.

---

## Patch 1 — MySQL 8 ResultSet Scrollability

**Problem:** MySQL 8 JDBC driver requires ResultSets to explicitly declare
scrollability. The original code creates default (forward-only) ResultSets and
then tries to call `rs.first()` or `rs.beforeFirst()`, which throws
`java.sql.SQLException: Operation not allowed for a forward only resultset`.

**Fix:** Change all `createStatement()` calls to use `TYPE_SCROLL_INSENSITIVE`
and `CONCUR_READ_ONLY`.

```java
// BEFORE (original):
Statement stmt = conn.createStatement();

// AFTER (patched):
Statement stmt = conn.createStatement(
    ResultSet.TYPE_SCROLL_INSENSITIVE,
    ResultSet.CONCUR_READ_ONLY
);
```

Apply this to **every** `createStatement()` call in the source tree:
```
src/com/savemgo/mgo1/GameServer.java
src/com/savemgo/mgo1/LobbyServer.java
src/com/savemgo/mgo1/AuthServer.java
```
(and any other file that creates a Statement)

---

## Patch 2 — Reserved Word `rank` Escaping

**Problem:** `rank` became a reserved keyword in MySQL 8. Queries using
`rank` as a column name without backticks fail with a syntax error.

**Fix:** Escape all occurrences of `rank` as a column name with backticks.

```sql
-- BEFORE:
SELECT rank FROM users WHERE ...
UPDATE users SET rank = ? WHERE ...

-- AFTER:
SELECT `rank` FROM users WHERE ...
UPDATE users SET `rank` = ? WHERE ...
```

Search for all occurrences:
```bash
grep -rn '"rank"' src/
grep -rn ' rank ' src/
```

---

## Patch 3 — ThreadLocal lobbyId

**Problem:** The original code stores `lobbyId` in a shared instance variable,
causing race conditions when multiple clients connect simultaneously.

**Fix:** Replace the shared field with a `ThreadLocal<Integer>`.

```java
// BEFORE:
private int lobbyId;

// AFTER:
private static final ThreadLocal<Integer> lobbyId = new ThreadLocal<>();

// Reading:
// BEFORE: this.lobbyId
// AFTER:  lobbyId.get()

// Writing:
// BEFORE: this.lobbyId = value;
// AFTER:  lobbyId.set(value);
```

---

## Patch 4 — Bind to 0.0.0.0

**Problem:** The original server binds to `localhost` (127.0.0.1), making it
unreachable from outside the container.

**Fix:** Change all `ServerSocket` / `bind()` calls to use `0.0.0.0`.

```java
// BEFORE:
new ServerSocket(port, backlog, InetAddress.getByName("localhost"));

// AFTER:
new ServerSocket(port, backlog, InetAddress.getByName("0.0.0.0"));
```

Or pass the bind address via system property (already handled by entrypoint.sh):
```java
String bindAddr = System.getProperty("server.bind", "0.0.0.0");
new ServerSocket(port, backlog, InetAddress.getByName(bindAddr));
```

---

## Patch 5 — Port Configuration via System Properties

**Problem:** Ports are hardcoded in the original source.

**Fix:** Read ports from JVM system properties with sensible defaults.

```java
int authPort  = Integer.parseInt(System.getProperty("server.port.auth",  "6731"));
int lobbyPort = Integer.parseInt(System.getProperty("server.port.lobby", "6732"));
int gamePort1 = Integer.parseInt(System.getProperty("server.port.game1", "6733"));
int gamePort2 = Integer.parseInt(System.getProperty("server.port.game2", "6734"));
int gamePort3 = Integer.parseInt(System.getProperty("server.port.game3", "6735"));
```

These are passed automatically by `docker/server/entrypoint.sh`.

---

## Patch 6 — Database Connection via System Properties

**Problem:** DB credentials hardcoded in the source.

**Fix:** Read from JVM system properties:

```java
String dbHost = System.getProperty("db.host", "localhost");
String dbPort = System.getProperty("db.port", "3306");
String dbName = System.getProperty("db.name", "mgops");
String dbUser = System.getProperty("db.user", "");
String dbPass = System.getProperty("db.password", "");

String url = "jdbc:mysql://" + dbHost + ":" + dbPort + "/" + dbName
           + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
Connection conn = DriverManager.getConnection(url, dbUser, dbPass);
```

---

## How to Apply

1. Fork `curi0us/mgops` → `NetworkMemories/mgops-docker`
2. Clone your fork locally
3. Apply each patch manually to the relevant `.java` files
4. Run `make build` — the Dockerfile compiles from source
5. Run `make run-daemon` to start

When in doubt, search for the BEFORE pattern with `grep -rn` and replace.
