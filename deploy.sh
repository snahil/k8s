#!/bin/bash

# Kubernetes Cluster Setup Script
# This script sets up a complete Kubernetes cluster with a highly available web application

set -e

echo "🚀 Starting Kubernetes Cluster Setup..."

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

# Deploy application
deploy_application() {
    print_status "Deploying application..."
    
    # Create namespace
    kubectl apply -f k8s/namespace.yaml
    
    # Deploy application
    kubectl apply -f k8s/app-deployment.yaml
    kubectl apply -f k8s/app-service.yaml
    
    # Deploy ingress controller
    kubectl apply -f k8s/ingress-controller.yaml
    kubectl apply -f k8s/ingress.yaml
    
    # Deploy PostgreSQL (bonus feature)
    kubectl apply -f k8s/postgres-pvc.yaml
    kubectl apply -f k8s/postgres-deployment.yaml
    kubectl apply -f k8s/postgres-service.yaml
    
    print_success "Application deployed successfully!"
}

# Wait for pods to be ready
wait_for_pods() {
    print_status "Waiting for pods to be ready..."
    
    # Wait for webapp pods
    kubectl wait --for=condition=ready pod -l app=webapp -n webapp --timeout=300s
    
    # Wait for postgres pod
    kubectl wait --for=condition=ready pod -l app=postgres -n webapp --timeout=300s
    
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
    echo "Health check: http://$MINIKUBE_IP/health"
    echo "App endpoint: http://$MINIKUBE_IP/app"
    
    echo ""
    echo "=== TESTING ENDPOINTS ==="
    
    # Test health endpoint
    echo "Testing health endpoint..."
    curl -s "http://$MINIKUBE_IP/health" || echo "Health endpoint not accessible yet"
    
    # Test app endpoint
    echo "Testing app endpoint..."
    curl -s "http://$MINIKUBE_IP/app" || echo "App endpoint not accessible yet"
    
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
    echo "Update image: kubectl set image deployment/webapp webapp=nginx:1.25-alpine -n webapp"
    echo "Rollback: kubectl rollout undo deployment/webapp -n webapp"
    echo "Check events: kubectl get events -n webapp"
    echo "Access minikube dashboard: minikube dashboard"
    echo "Open minikube service: minikube service webapp-service -n webapp"
}

# Main execution
main() {
    echo "=========================================="
    echo "   Kubernetes Cluster Setup Script"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    start_cluster
    deploy_application
    wait_for_pods
    show_status
    test_application
    show_commands
    
    echo ""
    print_success "Setup completed successfully! 🎉"
    echo ""
    echo "Your highly available web application is now running on Kubernetes!"
    echo "Check the README.md file for detailed documentation and troubleshooting."
}

# Run main function
main "$@" 