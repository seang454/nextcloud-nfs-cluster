# Nextcloud NFS Cluster with Keycloak Authentication

This repository contains Helm charts and Kubernetes manifests to deploy a High-Availability (HA) Cloud Storage Platform (Nextcloud) backed by a clustered NFS storage class, integrated with Keycloak OAuth2 SSO authentication via OAuth2-Proxy.

## Deployment Components

1. **[Traefik Ingress Controller](traefik-deployment.md)**: Configured as a DaemonSet to handle incoming HTTP/HTTPS traffic directly via node ports.
2. **[Keycloak & OAuth2-Proxy Authentication Stack](keycloak-Oauth2-proxy/)**: Handles OIDC Single Sign-On (SSO) authentication for Nextcloud.
3. **[Nextcloud Application Deployment](nextcloud-deployment/)**: Multi-replica Nextcloud app backed by MariaDB, Redis, and MinIO storage.

---

## TLS Certificate Flow (Traefik + cert-manager)

SSL certificates are automatically issued by **cert-manager** (via Let's Encrypt) and dynamically served by **Traefik**:

```text
Visitor Browser ◄──[ HTTPS (Secured by Traefik) ]──► Traefik Ingress
                                                       ▲
                                                       │ Loads Certs from
                                                       ▼
                                                 Kubernetes Secret
                                                       ▲
                                                       │ Updates Certs
                                                       ▼
                                                 Cert-Manager ◄──[ ACME Protocol ]──► Let's Encrypt
```

### Component Roles:
* **Cert-Manager**: Manages the lifecycle of certificates. It handles requesting, validating, and renewing the certificate files from Let's Encrypt, then saves them inside Kubernetes as Secrets.
* **Traefik Ingress**: Directs traffic into your cluster. It automatically loads the certificate files from the Kubernetes Secrets and uses them to establish secure HTTPS connections with visitors' browsers.
