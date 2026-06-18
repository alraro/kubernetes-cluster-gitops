# Kubernetes GitOps Home Lab

Kubernetes · ArgoCD · GitOps · OCI Free Tier · LetsEncrypt · Cloudflare · cert-manager · Sealed Secrets · Traefik

Personal Kubernetes homelab managed entirely through GitOps with ArgoCD using the app-of-apps pattern. Currently running on Oracle Cloud Infrastructure Free Tier, designed to be portable to any Kubernetes cluster.

## Repository Structure

```
kubernetes-cluster-gitops/
├── app-of-apps.yaml        # Root ArgoCD Application (entry point)
├── argo-install/            # Bootstrap manifests & helper scripts
├── trackers/                # ArgoCD Application definitions (one per component)
│   ├── infra/               #   Infrastructure trackers
│   └── apps/                #   Application trackers
├── infra/                   # Cluster infrastructure manifests
│   ├── argocd-interface/    #   ArgoCD web UI ingress
│   ├── https-certificate-managing/  #   cert-manager + ClusterIssuers
│   └── sealed-secrets/      #   Sealed Secrets controller
└── apps/                    # Workload manifests
    ├── minecraft/           #   Modded Minecraft server
    └── monitoring/          #   Grafana dashboards
```

## Infrastructure

| Component | Purpose | Method |
|-----------|---------|--------|
| **cert-manager** | Automated TLS certificates | Helm chart + LetsEncrypt + Cloudflare DNS-01 |
| **ClusterIssuers** | Public & private certificate authorities | LetsEncrypt ACME via Cloudflare API token |
| **Sealed Secrets** | Encrypted Kubernetes Secrets in Git | Bitnami Helm chart + kubeseal |
| **Traefik** | Ingress controller & TLS termination | Managed by cloud provider |
| **ArgoCD Interface** | Web UI at `argocd.private.alfonsoramos.dev` | Ingress + cert-manager TLS |

## Applications

### Minecraft Server

Modded Minecraft server running NeoForge 1.21.1 with a custom "Fauna & Orchestra" modpack. Deployed as a StatefulSet with 30Gi persistent storage (local-path StorageClass). The RCON password is stored as a SealedSecret.

**Scaled to 0 replicas by default — zero cost when not in use.** Scale up manually via `kubectl scale statefulset minecraft -n minecraft --replicas=1` to play.

- Image: `alraro/software-modpack-fauna:2.0.0`
- Game port: 25565 (LoadBalancer)
- RCON port: 25575 (ClusterIP)

### Grafana

Monitoring dashboards accessible at `grafana.private.alfonsoramos.dev` with automatic TLS via LetsEncrypt. Deployed via the official Grafana Helm chart with 2Gi persistent storage.

## Domain Strategy

- `*.private.alfonsoramos.dev` — private subdomain for administrative services (ArgoCD, Grafana)
- DNS-01 challenge via Cloudflare enables wildcard-capable certificate issuance
- Separate ClusterIssuers for public and private certificates

## Security

- TLS encryption on all ingress endpoints via cert-manager + LetsEncrypt
- Secrets encrypted at rest in the repository with Sealed Secrets
- ArgoCD serves HTTP internally; TLS is terminated at the Traefik ingress

## GitOps Workflow

1. Push changes to the `main` branch
2. ArgoCD's app-of-apps detects changes in `trackers/`
3. Each tracker Application syncs its corresponding manifests
4. Auto-sync + self-heal keeps the cluster state in sync with Git

## Portability

Not tied to any specific cloud provider. The same configuration can be deployed on any Kubernetes cluster (bare-metal, Raspberry Pi, Minikube, another cloud) with minimal changes:

- Swap `LoadBalancer` services for `NodePort` or `ClusterIP` + Ingress
- Adjust ClusterIssuers if the DNS provider changes

## Bootstrap

To deploy on a new cluster:

1. Install ArgoCD on the cluster
2. Apply `argo-install/argoCDinstall.yaml` (CRDs)
3. Create the `app-of-apps` Application pointing to `trackers/`
4. ArgoCD discovers and syncs all trackers automatically
