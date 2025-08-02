#!/bin/bash

# Terragrunt Deployment Script
# This script deploys the Kubernetes infrastructure using Terragrunt

set -e

echo "🚀 Starting Terragrunt Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terragrunt is installed
    if ! command -v terragrunt &> /dev/null; then
        print_error "Terragrunt is not installed. Please install Terragrunt first."
        echo "Installation: https://terragrunt.gruntwork.io/docs/getting-started/install/"
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if minikube is installed
    if ! command -v minikube &> /dev/null; then
        print_error "minikube is not installed. Please install minikube first."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker Desktop first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Start minikube cluster
start_cluster() {
    print_status "Starting minikube cluster..."
    
    # Check if minikube is already running
    if minikube status | grep -q "Running"; then
        print_warning "Minikube is already running. Skipping cluster start."
        return
    fi
    
    # Start minikube with ingress addon
    minikube start --driver=docker --cpus=2 --memory=4096 --addons=ingress
    
    # Enable ingress addon
    minikube addons enable ingress
    
    print_success "Minikube cluster started successfully!"
}

# Deploy infrastructure with Terragrunt
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terragrunt..."
    
    # Navigate to the dev environment
    cd terragrunt/environments/dev
    
    # Initialize Terragrunt
    print_status "Initializing Terragrunt..."
    terragrunt init
    
    # Plan the deployment
    print_status "Planning deployment..."
    terragrunt plan
    
    # Apply the deployment
    print_status "Applying deployment..."
    terragrunt apply -auto-approve
    
    # Show outputs
    print_status "Infrastructure outputs:"
    terragrunt output
    
    # Navigate back to root
    cd ../../..
    
    print_success "Infrastructure deployed successfully!"
}

# Wait for pods to be ready
wait_for_pods() {
    print_status "Waiting for pods to be ready..."
    
    # Wait for webapp pods
    kubectl wait --for=condition=ready pod -l app=webapp -n webapp --timeout=300s
    
    # Wait for postgres pod (if enabled)
    if kubectl get pods -n webapp -l app=postgres &> /dev/null; then
        kubectl wait --for=condition=ready pod -l app=postgres -n webapp --timeout=300s
    fi
    
    # Wait for ingress controller
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx --timeout=300s
    
    print_success "All pods are ready!"
}

# Show cluster status
show_status() {
    print_status "Showing cluster status..."
    
    echo ""
    echo "=== NODES ==="
    kubectl get nodes -o wide
    
    echo ""
    echo "=== PODS ==="
    kubectl get pods -n webapp -o wide
    
    echo ""
    echo "=== SERVICES ==="
    kubectl get services -n webapp
    
    echo ""
    echo "=== INGRESS ==="
    kubectl get ingress -n webapp
    
    echo ""
    echo "=== PERSISTENT VOLUME CLAIMS ==="
    kubectl get pvc -n webapp
}

# Test application
test_application() {
    print_status "Testing application..."
    
    # Get minikube IP
    MINIKUBE_IP=$(minikube ip)
    
    echo ""
    echo "=== APPLICATION ENDPOINTS ==="
    echo "Main application: http://$MINIKUBE_IP"
    echo "Hello endpoint: http://$MINIKUBE_IP/hello"
    echo "Health check: http://$MINIKUBE_IP/health"
    
    echo ""
    echo "=== TESTING ENDPOINTS ==="
    
    # Test main endpoint
    echo "Testing main endpoint..."
    curl -s "http://$MINIKUBE_IP/" || echo "Main endpoint not accessible yet"
    
    # Test hello endpoint
    echo "Testing hello endpoint..."
    curl -s "http://$MINIKUBE_IP/hello" || echo "Hello endpoint not accessible yet"
    
    # Test health endpoint
    echo "Testing health endpoint..."
    curl -s "http://$MINIKUBE_IP/health" || echo "Health endpoint not accessible yet"
    
    echo ""
    print_success "Application testing completed!"
}

# Show useful commands
show_commands() {
    echo ""
    echo "=== USEFUL COMMANDS ==="
    echo "Check pod logs: kubectl logs -n webapp deployment/webapp"
    echo "Check postgres logs: kubectl logs -n webapp deployment/postgres"
    echo "Scale deployment: kubectl scale deployment webapp --replicas=5 -n webapp"
    echo "Update image: kubectl set image deployment/webapp webapp=hashicorp/http-echo:latest -n webapp"
    echo "Rollback: kubectl rollout undo deployment/webapp -n webapp"
    echo "Check events: kubectl get events -n webapp"
    echo "Access minikube dashboard: minikube dashboard"
    echo "Open minikube service: minikube service webapp-service -n webapp"
    echo ""
    echo "=== TERRAGRUNT COMMANDS ==="
    echo "Plan changes: cd terragrunt/environments/dev && terragrunt plan"
    echo "Apply changes: cd terragrunt/environments/dev && terragrunt apply"
    echo "Destroy infrastructure: cd terragrunt/environments/dev && terragrunt destroy"
    echo "Show outputs: cd terragrunt/environments/dev && terragrunt output"
}

# Main execution
main() {
    echo "=========================================="
    echo "   Terragrunt Infrastructure Deployment"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    start_cluster
    deploy_infrastructure
    wait_for_pods
    show_status
    test_application
    show_commands
    
    echo ""
    print_success "Terragrunt deployment completed successfully! 🎉"
    echo ""
    echo "Your Hello World application is now running on Kubernetes!"
    echo "Check the README.md file for detailed documentation and troubleshooting."
}

# Run main function
main "$@" 