# Gateway API (nginx, cause its free)

## Configure and Run
1. RUN IT `k3d cluster create --config local-k3d.yaml --disable=traefik@server:0` OR `k3d cluster create --config local-k3d-gateway.yaml`
1. KILL IT `k3d cluster delete --config local-k3d-gateway.yaml`
1. `kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.6.2" | kubectl apply -f -`
1. `helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway`

1. Install ArgoCD

1. Apply `argocd-gateway-api.yaml`
1. Test