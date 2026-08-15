# Nextcloud Authentication & Recovery Guide

This guide provides instructions for daily user login, Keycloak administration, self-service registration, and emergency disaster recovery procedures for your Cloud Storage Platform.

---

## 1. Daily User Access (Single Sign-On)

For daily operations, access to Nextcloud is secured via Single Sign-On (SSO) integrated with Keycloak.

* **Nextcloud URL:** [https://nextcloud.seang.shop/](https://nextcloud.seang.shop/)
* **Login Type:** Click the **Log in with Keycloak** button (or you will be automatically redirected).

### Pre-Created Administrator Credentials
Use these credentials to sign in and configure Nextcloud with full administrator rights:
* **Username:** `nextcloud-admin`
* **Password:** `nextcloudpass123`

---

## 2. User Registration (Self-Service)

Self-service registration is enabled on Keycloak. If a new user needs access to Nextcloud:
1. Go to [https://nextcloud.seang.shop/](https://nextcloud.seang.shop/).
2. On the Keycloak sign-in screen, click **Register**.
3. Fill out the registration form.
4. Once registered, Keycloak will authenticate the user and redirect them back to Nextcloud.
5. Nextcloud's `oidc_login` app will dynamically create their account locally on their first login—**no manual account creation is required in Nextcloud**.

---

## 3. Keycloak Master Administration

To manage realms, client configurations, or add users manually, use the Keycloak Admin Console.

* **Keycloak Admin URL:** [https://keycloak.seang.shop/admin/](https://keycloak.seang.shop/admin/)
* **Realm:** `master`
* **Username:** `admin`
* **Password:** `CHANGE_ME_KEYCLOAK_ADMIN`

---

## 4. Emergency Disaster Recovery (Keycloak Offline)

If Keycloak or the OAuth2 Proxy goes offline, the perimeter gateway will block all access and return a `502 Bad Gateway` error. Follow these steps to bypass the gateway and log in with the emergency local administrator account.

### Step 4.1: Disable the Perimeter Gate (SSO Bypass)
From your terminal, edit Nextcloud's production values file to disable the ForwardAuth middleware:

1. Open [`nextcloud-deployment/environments/production-values.yaml`](file:///home/window/nextcloud-nfs-cluster/nextcloud-deployment/environments/production-values.yaml).
2. Under `nextcloud.traefik.middlewares.forwardAuth`, change `enabled` to `false`:
   ```yaml
         forwardAuth:
           enabled: false
   ```
3. Apply the configuration change to your Kubernetes cluster:
   ```bash
   helm upgrade csp . -f environments/production-values.yaml -n nextcloud-prod
   ```

### Step 4.2: Log in as Emergency Local Admin
1. Open the direct login link in your browser:
   [https://nextcloud.seang.shop/login?direct=1](https://nextcloud.seang.shop/login?direct=1)
2. Nextcloud will display its native local login fields instead of redirecting.
3. Sign in using the local admin credentials:
   * **Username:** `admin`
   * **Password:** `adminpass123`

---

## 5. Restoring Perimeter Security

Once Keycloak is back online, re-enable the gateway protection:

1. Open [`nextcloud-deployment/environments/production-values.yaml`](file:///home/window/nextcloud-nfs-cluster/nextcloud-deployment/environments/production-values.yaml).
2. Under `nextcloud.traefik.middlewares.forwardAuth`, change `enabled` back to `true`:
   ```yaml
         forwardAuth:
           enabled: true
   ```
3. Redeploy the configuration to the cluster:
   ```bash
   helm upgrade csp . -f environments/production-values.yaml -n nextcloud-prod
   ```
