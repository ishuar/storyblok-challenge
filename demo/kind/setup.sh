#!/bin/bash

# Strict mode configuration
set -euo pipefail
trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

# Script constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REQUIRED_TOOLS=("kubectl" "helm" "kind")
readonly KIND_CLUSTER_NAME="storyblok"
readonly EXPECTED_CONTEXT="kind-${KIND_CLUSTER_NAME}"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging functions
log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"; }
debug() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $1${NC}"; }

# Error handler
error_handler() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command=$4
    local error_trace=$5

    error "Error occurred in script at line: $line_no"
    error "Command: $last_command"
    error "Exit code: $exit_code"

    if [[ -n "$error_trace" ]]; then
        error "Error trace: $error_trace"
    fi
}

# Check if running on macOS
check_platform() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script is designed for macOS. Please adapt it for your platform."
        exit 1
    fi
}

# Check for required tools
check_dependencies() {
    local missing_tools=()

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -ne 0 ]]; then
        if [[ " ${missing_tools[*]} " =~ " kind " ]]; then
            log "Installing Kind using Homebrew..."
            brew install kind || warn "Kind installation failed but continuing..."
            missing_tools=("${missing_tools[@]/kind/}")
        fi

        if [[ ${#missing_tools[@]} -ne 0 ]]; then
            error "Required tools missing: ${missing_tools[*]}"
            error "Please install the missing tools and try again."
            log "You can install them using Homebrew: brew install ${missing_tools[*]}"
            exit 1
        fi
    fi
}

# Wait for pods in a namespace to be ready
wait_for_pods() {
    local namespace=$1
    local label_selector=${2:-""} # Optional label selector
    local timeout=${3:-300} # Default timeout of 5 minutes
    local start_time=$(date +%s)

    log "Waiting for pods in namespace '$namespace' to be ready..."

    while true; do
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))

        if [[ $elapsed_time -gt $timeout ]]; then
            error "Timeout waiting for pods in namespace '$namespace'"
            return 1
        fi

        if kubectl wait --for=condition=Ready pods --all  -l "$label_selector" -n "$namespace" --timeout=30s &> /dev/null; then
            log "All pods in namespace '$namespace' are ready"
            return 0
        fi

        debug "Still waiting for pods in namespace '$namespace'... ($elapsed_time seconds elapsed)"
        sleep 5
    done
}

# Create and configure kind cluster
setup_kind_cluster() {
    log "Creating Kind cluster with custom configuration..."
    if kind get clusters | grep -q "^${KIND_CLUSTER_NAME}$"; then
        warn "Cluster '${KIND_CLUSTER_NAME}' already exists, skipping creation"
    else
        kind create cluster --config "${SCRIPT_DIR}/config/config.yaml"
    fi

    # Verify correct context
    local current_context
    current_context=$(kubectl config current-context)
    if [[ "$current_context" != "$EXPECTED_CONTEXT" ]]; then
        error "Wrong kubectl context. Expected '${EXPECTED_CONTEXT}', got '${current_context}'"
        exit 1
    fi
}

# Install Nginx Ingress
install_nginx_ingress() {
    log "Installing Nginx Ingress controller..."
    kubectl apply -k "${SCRIPT_DIR}/config/"
    wait_for_pods "ingress-nginx" "app.kubernetes.io/component=controller"
}

# Install Flagger and its components
install_flagger() {
    log "Installing Flagger..."y
    helm repo add flagger https://flagger.app
    helm repo update

    helm upgrade --install flagger flagger/flagger \
        --namespace flagger \
        --set prometheus.install=true \
        --set meshProvider=kubernetes \
        --version 1.41.0 \
        --create-namespace

    wait_for_pods "flagger" "app.kubernetes.io/name=flagger"

    log "Installing Flagger load tester..."
    export NAMESPACE=pod-info
    helm upgrade -i flagger-loadtester flagger/loadtester \
        --namespace="$NAMESPACE" \
        --version 0.35.0 \
        --create-namespace

    wait_for_pods "$NAMESPACE" "app.kubernetes.io/name=loadtester"
}

# Install ArgoCD
install_argocd() {
    log "Installing ArgoCD..."
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update

    helm upgrade -i argocd argo/argo-cd \
        --namespace=argocd \
        --version=8.0.14 \
        --values "${SCRIPT_DIR}/argocd/values.yaml" \
        --create-namespace

    wait_for_pods "argocd" "app.kubernetes.io/instance=argocd"

    log "Applying repository secret..."
    log "Only Possible on the local machine of ::ishuar::"
    kubectl apply -f "${SCRIPT_DIR}/argocd/this-repository.yaml"
}

# Install PodInfo application
install_podinfo() {
    log "Installing PodInfo..."
    kubectl apply -f "${SCRIPT_DIR}/argocd/application.yaml"
}

# Main execution
main() {
    log "Starting setup process..."

    check_platform
    check_dependencies
    setup_kind_cluster
    install_nginx_ingress
    install_flagger
    install_argocd
    install_podinfo

    log "Setup completed successfully!"
    log "You can check all applications: kubectl get pods --all-namespaces"
}

# Execute main function
main
