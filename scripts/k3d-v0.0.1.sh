LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

log_output() {
    "$@" >> "$LOG_FILE" 2>&1
}

log_output kubectl apply -f something.yaml

# helm repo add argo https://argoproj.github.io/argo-helm > /dev/null
log_output helm repo add argo https://argoproj.github.io/argo-helm

info "Logs saved to ${BLUE}${LOG_FILE}${NC}"


# kubectl kustomize "https://..." | kubectl apply -f - > /dev/null
log_output bash -c 'kubectl kustomize "https://..." | kubectl apply -f -'
