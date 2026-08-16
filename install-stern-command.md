# 🚀 How to Install & Read Stern Logs on Ubuntu

[Stern](https://github.com/stern/stern) allows you to tail multiple Kubernetes pods and containers simultaneously with color-coded output.

---

## 📥 Installation Command (Ubuntu / Linux x86_64)

Run the following command to download and install `stern` to `/usr/local/bin`:

```bash
curl -sL https://github.com/stern/stern/releases/download/v1.32.0/stern_1.32.0_linux_amd64.tar.gz | tar -xz -C /tmp
sudo install -m 755 /tmp/stern /usr/local/bin/stern
```

### Verify Installation
```bash
stern --version
```

---

## 📊 Visual Format Breakdown of Stern Log Lines

### 1. Default Format (Single Namespace)
Command: `stern -n keycloak-oauth2 .`

```text
keycloak-oauth2-postgres-6f4fb45978-l9kck postgres 2026-08-16 14:36:04.393 UTC [1] LOG: database system is ready
└─────────────┬──────────────────────────┘ └───┬────┘ └──────────────────────────────────────┬────────────────────────┘
              │                                │                                             │
        1. POD NAME                    2. CONTAINER NAME                              3. LOG MESSAGE
 (Deployment name + unique pod hash)  (Container running inside pod)            (Timestamp, Log Level & Text)
```

---

### 2. All-Namespaces Format
Command: `stern -A .`

When streaming across **all namespaces**, `stern` adds the **Namespace** to the very beginning:

```text
keycloak-oauth2 keycloak-oauth2-postgres-6f4fb45978-l9kck postgres 2026-08-16 14:36:04.393 UTC [1] LOG: ready
└──────┬──────┘ └─────────────┬──────────────────────────┘ └───┬────┘ └──────────────────┬──────────────────┘
       │                      │                                │                         │
  1. NAMESPACE           2. POD NAME                    3. CONTAINER NAME          4. LOG MESSAGE
```

---

### 3. Container Lifecycle Symbols (+ and -)

`stern` prints special lifecycle lines when containers start or stop:

| Event Line | Symbol | What it Means |
| :--- | :---: | :--- |
| `+ pod-name › container-name` | **`+`** | Container **Started** / Created |
| `- pod-name › container-name` | **`-`** | Container **Finished** / Exited cleanly (`Exit Code 0`) |

#### Lifecycle Example in Output:
```text
+ keycloak-oauth2-postgres-6f4fb45978-l9kck › init-chmod-data   <-- (Init Container STARTED)
keycloak-oauth2-postgres-6f4fb45978-l9kck init-chmod-data fixing permissions...
- keycloak-oauth2-postgres-6f4fb45978-l9kck › init-chmod-data   <-- (Init Container FINISHED)
+ keycloak-oauth2-postgres-6f4fb45978-l9kck › postgres          <-- (Main Container STARTED)
keycloak-oauth2-postgres-6f4fb45978-l9kck postgres starting PostgreSQL 16...
```

---

### 4. Color-Coding Feature
* `stern` gives **each pod name a different color** (e.g. green for Postgres, blue for Keycloak, yellow for OAuth2-Proxy).
* This lets you instantly spot which application wrote a log line without having to read the pod name every time!

---

## 📖 Universal Guide to Reading Stern Logs

### 🟢 Universal SUCCESS Signals (Where to look)

| Signal | What it looks like | What it means |
| :--- | :--- | :--- |
| **Log Levels** | `INFO`, `NOTICE`, `SUCCESS` | Normal healthy operation |
| **HTTP Status** | `200`, `201`, `204`, `302` | Request succeeded |
| **App Startup** | `Listening on port...`, `Started in X.XXs`, `Ready to accept connections` | Application is online |
| **Init Container** | `- pod-name › init-container` | Init task completed and exited with Code 0 |

---

### 🔴 Universal ERROR Signals (Where to look)

| Signal | What it looks like | What it means |
| :--- | :--- | :--- |
| **Log Levels** | `FATAL`, `ERROR`, `CRITICAL`, `PANIC`, `EXCEPTION` | Application crash or failure |
| **HTTP Status** | `500`, `502`, `503`, `504` | Server crashed / gateway failed |
| **Network Errors**| `Connection refused`, `Timeout`, `Host not found` | Dependency is down or unreachable |
| **Permission Errors**| `Permission denied`, `Wrong ownership`, `Access denied` | Storage or RBAC permission issue |
| **Memory Errors** | `OOMKilled`, `Exit Code 137`, `Out of Memory` | Pod ran out of RAM |

---

## 💡 Useful Stern Filter & Usage Commands

### 1. Stream logs from ALL pods in a specific namespace
```bash
stern -n keycloak-oauth2 .
```

### 2. Filter to see ONLY errors in real-time
```bash
stern -n keycloak-oauth2 . -E "error|fatal|panic|exception"
```

### 3. Hide repetitive ping/health-check noise
```bash
stern -n keycloak-oauth2 . -e "kube-probe"
```

### 4. Stream logs matching specific pod names (e.g. `keycloak` or `postgres`)
```bash
stern -n keycloak-oauth2 "keycloak|postgres"
```

### 5. Tail recent logs (last 50 lines) and stream live updates
```bash
stern -n keycloak-oauth2 . --tail 50
```

### 6. Stream logs generated in the last 15 minutes
```bash
stern -n keycloak-oauth2 . --since 15m
```
