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