#!/usr/bin/env bash
# Dependencies: k3d, kubectl, helm, yq

set -e

CLUSTER_NAME="local-k3d"
ARGO_NAMESPACE="argocd"
GATEWAY_MODE="${3:-gateway}"  # Default to 'gateway' if not provided
CLUSTER="${2:-dev}"

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

if [[ "$CLUSTER" == "istio" ]]; then
    GATEWAY_MODE="ingress"
fi

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

    helm repo update > /dev/null

    step "Creating and labeling the argocd namespace"
    kubectl create namespace argocd || true
    kubectl label namespace argocd istio-injection=enabled --overwrite

    install_sealed_secrets

    if [[ "$CLUSTER" == "istio" ]]; then
        install_istio
    fi

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

install_sealed_secrets() {
    step "Installing Sealed Secrets controller"
    kubectl create namespace secrets || true

    helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets > /dev/null
    helm repo update > /dev/null

    kubectl create namespace sealed-secrets || true
    kubectl create namespace rabbitmq || true
    kubectl apply -f ../example-secrets/sealed-secrets-sealing-key.yaml > /dev/null

    helm install sealed-secrets sealed-secrets/sealed-secrets \
        --namespace sealed-secrets \
        --version 2.17.2 > /dev/null \
        --values ../apps/sealed-secrets/values/values.yaml > /dev/null
    success "Sealed Secrets installed and custom key applied"

    kubectl apply -f ../apps/secrets/ > /dev/null
}

install_istio() {
    step "Starting Istio installation"

    ISTIO_VERSION="1.22.0"

    if ! command -v istioctl &> /dev/null; then
        step "Downloading istioctl"
        curl -sSL https://istio.io/downloadIstio | ISTIO_VERSION=1.22.0 TARGET_ARCH=arm64 sh - > /dev/null 2>&1

        step "Installing istioctl"
        sudo mv istio-*/bin/istioctl /usr/local/bin/
    fi

    step "Istio precheck"
    istioctl x precheck

    step "Installing Istio"
    istioctl install \
        --set profile=demo \
        --set values.gateways.istio-ingressgateway.type=ClusterIP \
        -y
    
    kubectl apply -f ../apps/istio/manifests

    step "Cleaning up..."
    rm -rf istio-${ISTIO_VERSION}
}

install_argocd() {
    step "Installing Argo CD"

    helm repo add argo https://argoproj.github.io/argo-helm > /dev/null
    helm repo update > /dev/null

    helm install argocd argo/argo-cd \
        --namespace argocd \
        --create-namespace \
        --version 8.0.17 \
        --values ../apps/argocd/values/values.yaml > /dev/null

    if [[ "$CLUSTER" == "istio" ]]; then
        step "Applying Istio VirtualService for Argo CD"
        kubectl apply -f ../apps/argocd/helm/templates/virtual-service.yaml
    fi

    # kubectl delete job argocd-redis-secret-init -n argocd

    step "Waiting for Argo CD server to be ready..."
    kubectl rollout status deployment argocd-server -n argocd --timeout=300s > /dev/null

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
    step "Deploying Argo CD apps based on cluster inventory..."

    for app_dir in ../apps/*/; do
        app=$(basename "$app_dir")
        clusters_file="${app_dir}/clusters.yaml"
        argo_app_path="${app_dir}/application.yaml"

        # Skip if application.yaml does not exist
        if [[ ! -f "$argo_app_path" ]]; then
            warn "No application.yaml found for app: $app"
            continue
        fi

        # If clusters.yaml is missing, deploy unconditionally
        if [[ ! -f "$clusters_file" ]]; then
            step "Deploying app without cluster filter: $app"
            kubectl apply -n argocd -f "$argo_app_path" > /dev/null
            continue
        fi

        # Check if current cluster inventory is listed
        if yq e '.clusters[]' "$clusters_file" | grep -qx "$CLUSTER"; then
            step "Deploying app: $app (matches cluster: $CLUSTER)"
            kubectl apply -n argocd -f "$argo_app_path" > /dev/null
        else
            step "Skipping app: $app (cluster $CLUSTER not in clusters.yaml)"
        fi
    done

    success "Finished deploying Argo CD apps."
}

usage() {
    echo -e "${YELLOW}Usage:${NC} $0 {up|down} [dev|istio] [gateway|ingress]"
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