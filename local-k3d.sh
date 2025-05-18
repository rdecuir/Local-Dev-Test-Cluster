#!/bin/bash

set -e

CLUSTER_NAME="local-k3d"
ARGO_NAMESPACE="argocd"

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
    # k3d cluster create "$CLUSTER_NAME" --agents 3 --port "80:80@loadbalancer" --port "443:443@loadbalancer"
    k3d cluster create "$CLUSTER_NAME" --agents 3 --port "80:80@loadbalancer" --port "443:443@loadbalancer" --k3s-arg "--disable=traefik@server:*"
    success "Cluster created."

    step "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=60s > /dev/null
    success "All nodes ready."

    install_argocd
    install_api_gateway
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
    --create-namespace \
    --set-string configs.secret.argocdServerAdminPassword='$2a$10$9DMh/raHJuUHlycOhGe/Ze1rB7KXMDQuDScCfWMxHE7zS7IxsaCXy' \
    --set-string "configs.params.server\.insecure=true" > /dev/null
    # --values apps/figureout-a-name/argocd/argocd.values.yaml
    # --version <CHART_VERSION>

    step "Waiting for Argo CD server to be ready..."
    kubectl rollout status deployment argocd-server -n argocd --timeout=120s > /dev/null

    success "Argo CD is installed and running."

    step "Access Argo CD UI at: ${BLUE}http://argocd.localhost${NC}"

    # PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    PASS=$(kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.admin\.password}" | base64 -d)
    echo -e "${YELLOW}Initial admin password:${NC} ${GREEN}${PASS}${NC}"
}

install_api_gateway() {
    step "Installing API Gateway"
    
    kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.6.2" | kubectl apply -f - > /dev/null
    helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway > /dev/null
    kubectl apply -f research-topics/gateway-api-nginx/argocd-gateway-api.yaml > /dev/null

    success "API Gateway installed."
}

usage() {
    echo -e "${YELLOW}Usage:${NC} $0 {up|down}"
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
