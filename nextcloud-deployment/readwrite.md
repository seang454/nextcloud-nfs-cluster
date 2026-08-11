# Using ReadWriteMany (RWX) with Nextcloud on Kubernetes (NFS Storage)

Your cluster is configured to use **NFS Storage** (`nfs-client` / `nfs-pvc`) with `ReadWriteMany` (RWX) mode for Nextcloud.

## 1. NFS Persistent Volume Claim Setup
You can either use a pre-existing PVC named `nfs-pvc` or allow Helm to dynamically provision a PVC via your NFS storage class (`nfs-client`).

### Example existing PVC definition (`nfs-pvc`):
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: "nfs-client"
```

In `values.yaml`, set:
```yaml
nextcloud:
  persistence:
    enabled: true
    existingClaim: "nfs-pvc"   # Mounts nfs-pvc directly into Nextcloud
```

## 2. Multi-Replica Scaling with NFS
Since NFS provides `ReadWriteMany` access, Nextcloud can be scaled across multiple pods/nodes (`replicaCount: 2+`).

### Best Practices for Multiple Replicas:
- **MinIO S3 for User Data:** Primary user data files are stored in MinIO object storage. The NFS volume stores Nextcloud PHP core files.
- **Cron Jobs:** Background tasks run safely via the included Kubernetes `CronJob` (`cron.php`).
- **Database Migrations (`occ upgrade`):** When updating Nextcloud versions, ensure upgrades are executed from a single pod before scaling up.
