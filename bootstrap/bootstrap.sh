#!/usr/bin/env bash
# Dependencies: k3d, kubectl, helm, yq

set -e

CLUSTER_NAME="local-k3d"
ARGO_NAMESPACE="argocd"
GATEWAY_MODE="${3:-gateway}"  # Default to 'gateway' if not provided
CLUSTER_INVENTORY="${2:-default}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[✔]${NC} $1"; }
step()    { echo -e "${YELLOW}[➤]${NC} $1"; }

create_cluster() {
    step "Creating k3d cluster: ${CLUSTER_NAME}"
    if [[ "$GATEWAY_MODE" == "gateway" ]]; then
        k3d cluster create "$CLUSTER_NAME" --agents 3 --port "80:80@loadbalancer" --port "443:443@loadbalancer" --k3s-arg "--disable=traefik@server:*" > /dev/null
    else
        k3d cluster create "$CLUSTER_NAME" --agents 3 --port "80:80@loadbalancer" --port "443:443@loadbalancer" > /dev/null
    fi
    success "Cluster created."

    step "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=60s > /dev/null
    success "All nodes ready."

    install_argocd
    if [[ "$GATEWAY_MODE" == "gateway" ]]; then
            install_api_gateway
        else
            step "Skipping API Gateway installation (mode: $GATEWAY_MODE)"
    fi

    deploy_argo_apps
}

delete_cluster() {
    step "Deleting k3d cluster: ${CLUSTER_NAME}"
    k3d cluster delete "$CLUSTER_NAME"
    success "Cluster deleted."
}

install_argocd() {
    step "Installing Argo CD"

    helm repo add argo https://argoproj.github.io/argo-helm > /dev/null
    helm repo update > /dev/null

    helm install argocd argo/argo-cd \
    --namespace argocd \
    --create-namespace > /dev/null
    # --set-string configs.secret.argocdServerAdminPassword='$2a$10$9DMh/raHJuUHlycOhGe/Ze1rB7KXMDQuDScCfWMxHE7zS7IxsaCXy' \
    # --set-string "configs.params.server\.insecure=true" > /dev/null
    # --values apps/figureout-a-name/argocd/argocd.values.yaml
    # --version <CHART_VERSION>

    step "Waiting for Argo CD server to be ready..."
    kubectl rollout status deployment argocd-server -n argocd --timeout=180s > /dev/null

    success "Argo CD is installed and running."

    step "Access Argo CD UI at: ${BLUE}http://argocd.localhost${NC}"
}

install_api_gateway() {
    step "Installing API Gateway"
    
    kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.6.2" | kubectl apply -f - > /dev/null
    helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway > /dev/null 2>&1
    kubectl apply -f ../research-topics/gateway-api-nginx/argocd-gateway-api.yaml > /dev/null

    success "API Gateway installed."
}

deploy_argo_apps() {
    step "Deploying Argo CD apps from values file..."

    local VALUES_FILE="cluster-inventories/${CLUSTER_INVENTORY}.yaml"
    if [[ ! -f "$VALUES_FILE" ]]; then
        error "Missing values file: $VALUES_FILE"
        exit 1
    fi

    apps=()
    while IFS= read -r app; do
    apps+=("$app")
    done < <(yq e '.apps[]' "$VALUES_FILE")

    if [[ ${#apps[@]} -eq 0 ]]; then
        warn "No applications listed under 'apps' in $VALUES_FILE"
        return
    fi

    for app in "${apps[@]}"; do
        local manifest_path="../argo-apps/${app}.yaml"
        if [[ -f "$manifest_path" ]]; then
            step "Deploying app: $app"
            kubectl apply -n argocd -f "$manifest_path" > /dev/null
        else
            warn "App manifest not found for: $app ($manifest_path)"
        fi
    done

    success "Finished deploying Argo CD apps."
}

usage() {
    echo -e "${YELLOW}Usage:${NC} $0 {up|down} [default|cluster1] [gateway|ingress]"
    echo "       up      - Create cluster and optionally install API Gateway (default: gateway)"
    echo "       down    - Delete the cluster"
    echo "       gateway - Use API Gateway"
    echo "       ingress - Skip API Gateway (or configure ingress manually)"
    exit 1
}

case "$1" in
    up)
        create_cluster
        ;;
    down)
        delete_cluster
        ;;
    *)
        usage
        ;;
esac
