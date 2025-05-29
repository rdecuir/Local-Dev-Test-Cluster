## Manually deploy a k3d cluster
1. RUN IT `k3d cluster create --config local-k3d.yaml`
1. KILL IT `k3d cluster delete --config local-k3d.yaml`

---

## Manually install Argocd
1. `kubectl create namespace argocd`

1. `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`

1. `k apply -n argocd -f argo-apps/project.yaml` 

1. `k apply -n argocd -f argo-apps/root-app.yaml`

1. `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

1. `kubectl port-forward -n argocd svc/argocd-server 8080:443`

### OR
1.  ```
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    ```
1.  ```
    helm install argocd argo/argo-cd \
        --namespace argocd \
        --create-namespace \
        --set-string configs.secret.argocdServerAdminPassword='$2a$10$9DMh/raHJuUHlycOhGe/Ze1rB7KXMDQuDScCfWMxHE7zS7IxsaCXy' \
        --set-string "configs.params.server\.insecure=true"
        # --values path/to/values.yaml
        # --version <CHART_VERSION>
    ```
1. Generate password as bcrypt:
    ```
    htpasswd -nbBC 10 "" admin | tr -d ':\n' | sed 's/$2y/$2a/'
    ```

## How to find the right Helm chart version
1. helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
1. helm search repo sealed-secrets/sealed-secrets --versions

## Helm template
```
cd apps/goldilocks
helm template . -f ../../argo-apps/values.yaml -f values.yaml
```