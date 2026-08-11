# Cloud Storage Platform — Helm Chart (Traefik & NFS Enabled)

Production Kubernetes deployment of Nextcloud (drive/UI) backed by MariaDB
(metadata), Redis (locking/cache), and MinIO (S3-compatible primary object
storage).

- **Ingress Controller:** Native **Traefik CRDs** (`traefik.io/v1alpha1` `IngressRoute`, `Middleware`, `TLSOption`, `TLSStore`, `ServersTransport`). Standard Kubernetes `Ingress` is disabled/removed.
- **Storage:** **NFS Storage** (`nfs-client` / `nfs-pvc`) with `ReadWriteMany` (RWX) access mode.
- **Primary Domain:** `nextcloud.seang.shop`
- **Worker Node Public IP:** `35.201.128.109`

```
cloud-storage-platform/
├── Chart.yaml               # umbrella chart (no logic of its own)
├── values.yaml               # global defaults, nested per-subchart
├── templates/                 # shared NOTES.txt/_helpers.tpl
├── charts/
│   ├── mariadb/                # metadata store subchart
│   ├── redis/                  # locking/cache subchart
│   ├── minio/                  # S3 object storage subchart
│   └── nextcloud/               # php-fpm + nginx + Traefik CRDs subchart
└── environments/
    ├── dev-values.yaml
    ├── staging-values.yaml
    └── production-values.yaml
```

## Architecture

```
                 ┌───────────────┐
  Internet ─────►│    Traefik    │  (IngressRoute + Middlewares + cert-manager TLS)
                 └───────┬───────┘
                         ▼
               ┌───────────────────┐
               │   nextcloud Pod   │  (N replicas, NFS RWX storage)
               │ ┌───────┐ ┌──────┐│
               │ │ nginx │─│php-fpm││   NFS PVC: /var/www/html (nfs-pvc / nfs-client)
               │ └───────┘ └──────┘│
               └─────┬───────┬─────┘
                     ▼       ▼
             ┌──────────┐ ┌────────┐        ┌─────────────┐
             │ MariaDB  │ │ Redis  │        │   MinIO     │
             │(metadata)│ │(locks) │        │ (file bytes,│
             └──────────┘ └────────┘        │ S3 objects) │
                                            └─────────────┘
```

- **Traefik Custom Resources**:
  - `IngressRoute`: Fronts Nextcloud (`nextcloud.seang.shop`) and MinIO console.
  - `Middleware`: `api-rate-limit`, `oauth2-forward-auth`, `nextcloud-headers` (security headers), `nextcloud-redirectregex` (`.well-known` endpoints), `nextcloud-buffering` (10GB+ upload limits), `nextcloud-compress`, and `nextcloud-ip-allowlist` (`35.201.128.109/32`).
  - `TLSOption`: Enforces TLS 1.2+ and modern secure cipher suites.
  - `TLSStore`: Configures default TLS certificate secrets (`nextcloud-tls`).
  - `ServersTransport`: Configures `backend-internal-mtls` for mTLS/TLS backend communication.
- **MariaDB** stores metadata only (filenames, folder tree, users, shares, permissions).
- **Redis** provides distributed file locking and memcache.
- **MinIO** is configured as Nextcloud's *primary* S3 object storage (`OBJECTSTORE_S3_*` env vars).
- **NFS PVC (`nfs-pvc`)** provides `ReadWriteMany` storage mounted at `/var/www/html`.

## Prerequisites

- A Kubernetes cluster running **Traefik** (with `traefik.io/v1alpha1` CRDs installed).
- **NFS Provisioner** (`nfs-client-provisioner` / StorageClass `nfs-client`) or pre-created PVC `nfs-pvc`.
- `cert-manager` installed for TLS certificate issuance.
- Helm 3.x.

## Deploy

```bash
# Development
helm install csp-dev . -f environments/dev-values.yaml \
  -n nextcloud-dev --create-namespace

# Staging
helm install csp-staging . -f environments/staging-values.yaml \
  -n nextcloud-staging --create-namespace

# Production
helm install csp . -f environments/production-values.yaml \
  -n nextcloud-prod --create-namespace
```

Upgrade using `helm upgrade`.

## Encrypting file storage at rest

Once pods are healthy:
```bash
kubectl exec -it deploy/csp-nextcloud -c php-fpm -n nextcloud-prod -- \
  php occ app:enable encryption
kubectl exec -it deploy/csp-nextcloud -c php-fpm -n nextcloud-prod -- \
  php occ encryption:enable
kubectl exec -it deploy/csp-nextcloud -c php-fpm -n nextcloud-prod -- \
  php occ encryption:select-encryption-type
```
