# Local Dev Test Cluster (Bare Metal)

[[ToC]]

1. Install kubectl (env specific)

1. Install k3d
    - `wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash\n`

1. Fix terminal commands
    - `brew install bash-completion`
    - `vim ~/.zshrc`
        ```
        # Manually Added
        source <(kubectl completion zsh)
        alias k=kubectl
        complete -o default -F __start_kubectl k
        ```
    - `source ~/.zshrc`

## Configure and Run
1. RUN IT `k3d cluster create --config local-k3d.yaml`
1. KILL IT `k3d cluster delete --config local-k3d.yaml`

---

## Installing Argocd (Working, Need to fix issue with not auto deploying)
1. `kubectl create namespace argocd`

1. `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`

1. `k apply -n argocd -f argo-apps/project.yaml` 

1. `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

1. `kubectl port-forward -n argocd svc/argocd-server 8080:443`

WPngQhV3lFXWtl6H