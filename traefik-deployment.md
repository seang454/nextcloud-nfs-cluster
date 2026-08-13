# Traefik DaemonSet Installation with Helm

## 2. Add the Traefik Helm repository

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

The official Traefik Helm chart uses this repository.

---

## 3. Create the namespace

```bash
kubectl create namespace traefik
```

---

## 4. Install Traefik

From the directory containing `traefik-values.yaml`:

```bash
helm install traefik traefik/traefik \
  --namespace traefik \
  --values traefik-values.yaml \
  --wait
```

This installs Traefik using your custom `traefik-values.yaml`.

---

## 5. Verify the DaemonSet

Check the DaemonSet:

```bash
kubectl get daemonset -n traefik
```

You should see something similar to:

```text
NAME      DESIRED   CURRENT   READY
traefik   3         3         3
```

The number `3` assumes you have three eligible Kubernetes nodes.

---

## 6. Verify Traefik Pods

```bash
kubectl get pods -n traefik -o wide
```

You should have **one Traefik pod on each eligible node**.

For example:

```text
NAME             READY   STATUS    NODE
traefik-xxxxx    1/1     Running   node-01
traefik-yyyyy    1/1     Running   node-02
traefik-zzzzz    1/1     Running   node-03
```

---

## 7. Verify Host Ports

Because Traefik is configured to use `hostPort`, verify that ports `80` and `443` are configured:

```bash
kubectl get pods -n traefik -o yaml | grep -A5 hostPort
```

You should see:

```text
hostPort: 80
hostPort: 443
```

This means each Traefik pod can listen directly on the Kubernetes node's:

- TCP port `80` for HTTP
- TCP port `443` for HTTPS

---

## Architecture

```text
                    Kubernetes Cluster
                           |
          +----------------+----------------+
          |                |                |
       node-01          node-02          node-03
          |                |                |
       Traefik           Traefik          Traefik
       :80 :443          :80 :443         :80 :443
          |                |                |
          +----------------+----------------+
                           |
                    Kubernetes Service
                           |
                    Application Pods
```

## Important

Make sure ports `80` and `443` are not already being used by another service on the Kubernetes nodes.

If you are using **K3s**, check whether the built-in Traefik is already installed before deploying another Traefik instance. Two Traefik instances cannot both bind to the same host ports on the same node.

---

## TLS Certificate Flow (Traefik + cert-manager)

The SSL certificates are issued by **cert-manager** (via Let's Encrypt) and dynamically loaded and served by **Traefik**:

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

