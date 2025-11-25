# Local Dev Test Cluster (Bare Metal)

[[ToC]]

## Set up the environment

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

## Bootstrap a cluster

1. `./bootstrap.sh up cluster1`
1. Then navigate to http://argocd.localhost, you will need to wait roughly 5-8 mins for everything to complete and for argocd to come up.

## Patterns
The current use of this cluster configuration is Traefik handles external access control and Istio handles internal traffic as the service mesh. Yes Istio could replace traefik completely, but we need to honor what is currently in place and working.


Need to remove istio