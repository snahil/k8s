# Kubernetes Cluster Setup with Hello World Application

This project demonstrates a complete Kubernetes cluster setup with a highly available "Hello World" web application, NGINX Ingress Controller, and zero-downtime deployment capabilities. The infrastructure is managed using Terragrunt for better organization and reusability.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Cluster Setup](#cluster-setup)
- [Application Deployment](#application-deployment)
- [Ingress Configuration](#ingress-configuration)
- [Zero-Downtime Updates](#zero-downtime-updates)
- [Monitoring and Verification](#monitoring-and-verification)
- [Bonus Features](#bonus-features)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker Desktop installed and running
- kubectl CLI tool installed
- minikube (for local development)
- Terragrunt (for infrastructure management)
- curl or wget for testing endpoints

## Cluster Setup

### 1. Start Minikube Cluster

```bash
# Start minikube with ingress addon
minikube start --driver=docker --cpus=2 --memory=4096 --addons=ingress

# Enable ingress addon
minikube addons enable ingress

# Verify cluster is running
kubectl cluster-info
```

### 2. Verify Cluster Status

```bash
# Check nodes
kubectl get nodes

# Check all pods in kube-system namespace
kubectl get pods -n kube-system
```

## Application Deployment

### 1. Deploy the Hello World Application

The application is deployed using a highly available configuration with:
- Multiple replicas for high availability
- Resource requests and limits
- Rolling update strategy
- Health checks

```bash
# Apply the application deployment
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
```

**Or use the automated deployment script:**
```bash
./deploy.sh
```

### 2. Deploy NGINX Ingress Controller

```bash
# Apply ingress controller
kubectl apply -f k8s/ingress-controller.yaml
kubectl apply -f k8s/ingress.yaml
```

### 3. Deploy PostgreSQL Database (Bonus)

```bash
# Apply PostgreSQL deployment
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/postgres-pvc.yaml
```

## Ingress Configuration

The ingress is configured to route traffic to the application:

```bash
# Check ingress status
kubectl get ingress -n webapp

# Get the external IP (for minikube)
minikube service list
```

## Zero-Downtime Updates

The deployment is configured with rolling updates:

```bash
# Update the application image
kubectl set image deployment/webapp webapp=hashicorp/http-echo:latest

# Monitor the rolling update
kubectl rollout status deployment/webapp

# Rollback if needed
kubectl rollout undo deployment/webapp
```

## Monitoring and Verification

### 1. Check Pod Status

```bash
# Check all pods
kubectl get pods -n webapp

# Check pod details
kubectl describe pods -n webapp
```

### 2. Check Services

```bash
# List all services
kubectl get services -n webapp

# Check service details
kubectl describe service webapp-service -n webapp
```

### 3. Test Application Access

```bash
# Get minikube IP
minikube ip

# Test the application (replace IP with your minikube IP)
curl http://$(minikube ip)/hello

# Or use minikube service
minikube service webapp-service -n webapp
```

### 4. Check Ingress

```bash
# Check ingress status
kubectl get ingress -n webapp

# Test ingress access
curl -H "Host: webapp.local" http://$(minikube ip)/hello
```

## Bonus Features

### 1. Terragrunt Automation

The cluster can be provisioned using Terragrunt (see `terragrunt/` directory):

```bash
# Deploy using Terragrunt
./terragrunt-deploy.sh

# Or manually:
cd terragrunt/environments/dev
terragrunt init
terragrunt plan
terragrunt apply
```

### 2. Helm Charts

Application can be deployed using Helm:

```bash
# Install the application using Helm
helm install webapp ./helm/webapp
```

### 3. PostgreSQL Database

A PostgreSQL database is deployed as a stateful application:

```bash
# Check PostgreSQL status
kubectl get pods -n webapp -l app=postgres
kubectl get pvc -n webapp
```

## Kubernetes Manifests

All Kubernetes manifests are located in the `k8s/` directory:

- `namespace.yaml` - Application namespace
- `app-deployment.yaml` - Hello World application deployment
- `app-service.yaml` - Application service
- `ingress.yaml` - Ingress configuration
- `postgres-deployment.yaml` - PostgreSQL deployment
- `postgres-service.yaml` - PostgreSQL service
- `postgres-pvc.yaml` - PostgreSQL persistent volume claim

## Terragrunt Configuration

The infrastructure is managed using Terragrunt for better organization:

- `terragrunt/terragrunt.hcl` - Root configuration
- `terragrunt/environments/dev/` - Development environment
  - `terragrunt.hcl` - Environment-specific variables
  - `main.tf` - Infrastructure resources
  - `variables.tf` - Variable definitions
  - `outputs.tf` - Output values

## Screenshots and Verification Commands

### Pod Status
```bash
kubectl get pods -n webapp -o wide
```

### Node Status
```bash
kubectl get nodes -o wide
```

### Service List
```bash
kubectl get services -n webapp
```

### Ingress Access
```bash
kubectl get ingress -n webapp
curl -H "Host: webapp.local" http://$(minikube ip)/hello
```

## Troubleshooting

### Common Issues

1. **Minikube not starting**: Ensure Docker Desktop is running
2. **Ingress not working**: Check if ingress addon is enabled
3. **Pods in pending state**: Check resource availability
4. **Service not accessible**: Verify service configuration

### Debug Commands

```bash
# Check pod logs
kubectl logs -n webapp deployment/webapp

# Check events
kubectl get events -n webapp

# Check resource usage
kubectl top pods -n webapp
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace webapp

# Stop minikube
minikube stop

# Delete minikube cluster
minikube delete
```

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress       │    │   Hello World   │    │   PostgreSQL    │
│   Controller    │───▶│   Deployment    │───▶│   StatefulSet   │
│                 │    │   (3 replicas)  │    │   (1 replica)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

The application demonstrates:
- **High Availability**: Multiple replicas with anti-affinity
- **Scalability**: Horizontal Pod Autoscaler ready
- **Zero Downtime**: Rolling update strategy
- **Resource Management**: Proper requests and limits
- **Stateful Database**: PostgreSQL with persistent storage
- **Infrastructure as Code**: Terragrunt for infrastructure management 