#!/usr/bin/env bash
# Dependencies: k3d, kubectl, helm, yq

set -e

CLUSTER_NAME="local-k3d"
ARGO_NAMESPACE="argocd"
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

    k3d cluster create "$CLUSTER_NAME" --agents 3 --port "80:80@loadbalancer" --port "443:443@loadbalancer" > /dev/null

    success "Cluster created."

    step "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=60s > /dev/null
    success "All nodes ready."

    install_istio

    install_argocd

    deploy_argo_apps
}

delete_cluster() {
    step "Deleting k3d cluster: ${CLUSTER_NAME}"
    k3d cluster delete "$CLUSTER_NAME"
    success "Cluster deleted."
}

install_istio() {
    step "Installing Istio"
    step "Downloading istioctl"
    ISTIO_VERSION="1.22.0"
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.0 TARGET_ARCH=arm64 sh -

    step "Installing istioctl"
    sudo mv istio-*/bin/istioctl /usr/local/bin/
    istioctl version

    step "Istio precheck"
    istioctl x precheck

    step "Installing Istio"
    istioctl install \
        --set profile=demo \
        --set values.gateways.istio-ingressgateway.type=ClusterIP \
        -y

    step "Cleaning up..."
    rm -rf istio-1.22.0
}


install_argocd() {
    step "Creating and labeling the argocd namespace for Istio sidecar injection"
    kubectl create namespace argocd || true
    kubectl label namespace argocd istio-injection=enabled --overwrite

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

    # kubectl delete job argocd-redis-secret-init -n argocd


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

    apps=("istio" "argocd" "goldilocks" "sealed-secrets")

    for app in "${apps[@]}"; do
        local manifest_path="../../argo-apps/${app}.yaml"
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
