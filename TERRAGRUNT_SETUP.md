# Terragrunt Setup Guide

This guide explains how to install and use Terragrunt for managing the Kubernetes infrastructure.

## Installation

### macOS (using Homebrew)
```bash
brew install terragrunt
```

### Linux
```bash
# Download the latest version
curl -fsSL https://github.com/gruntwork-io/terragrunt/releases/download/v0.54.11/terragrunt_linux_amd64 -o terragrunt

# Make it executable
chmod +x terragrunt

# Move to a directory in your PATH
sudo mv terragrunt /usr/local/bin/
```

### Windows
```bash
# Using Chocolatey
choco install terragrunt

# Or download from GitHub releases
# https://github.com/gruntwork-io/terragrunt/releases
```

## Project Structure

```
terragrunt/
├── terragrunt.hcl                    # Root configuration
└── environments/
    └── dev/
        ├── terragrunt.hcl            # Environment variables
        ├── main.tf                   # Infrastructure resources
        ├── variables.tf              # Variable definitions
        └── outputs.tf                # Output values
```

## Usage

### 1. Deploy Infrastructure

```bash
# Navigate to the dev environment
cd terragrunt/environments/dev

# Initialize Terragrunt
terragrunt init

# Plan the deployment
terragrunt plan

# Apply the deployment
terragrunt apply
```

### 2. Update Infrastructure

```bash
# Make changes to main.tf or variables
# Then run:
terragrunt plan
terragrunt apply
```

### 3. Destroy Infrastructure

```bash
# Remove all resources
terragrunt destroy
```

### 4. Show Outputs

```bash
# Display all outputs
terragrunt output

# Display specific output
terragrunt output application_url
```

## Configuration

### Root terragrunt.hcl

The root configuration file defines:
- Common provider configuration
- Remote state configuration
- Shared variables

### Environment terragrunt.hcl

Each environment has its own configuration:
- Environment-specific variables
- Resource configurations
- Tags and labels

## Variables

Key variables that can be customized:

```hcl
# Application configuration
app_name    = "webapp"
app_image   = "hashicorp/http-echo:latest"
replicas    = 3

# Resource limits
cpu_request    = "50m"
memory_request = "64Mi"
cpu_limit      = "100m"
memory_limit   = "128Mi"

# Ingress configuration
ingress_host = "webapp.local"

# PostgreSQL configuration
postgres_enabled = true
postgres_image   = "postgres:15-alpine"
postgres_db      = "webapp"
postgres_user    = "postgres"
postgres_password = "postgres123"
postgres_storage = "1Gi"
```

## Benefits of Terragrunt

1. **DRY (Don't Repeat Yourself)**: Common configurations are defined once
2. **Environment Management**: Easy to manage multiple environments
3. **State Management**: Centralized state file management
4. **Variable Management**: Environment-specific variables
5. **Consistency**: Ensures consistent deployments across environments

## Troubleshooting

### Common Issues

1. **Provider not found**: Run `terragrunt init`
2. **State lock**: Check for running Terraform processes
3. **Permission denied**: Ensure proper file permissions
4. **Kubernetes connection**: Verify `kubectl` is configured

### Debug Commands

```bash
# Show Terragrunt configuration
terragrunt show

# Validate configuration
terragrunt validate

# Show plan in detail
terragrunt plan -detailed-exitcode

# Show logs
terragrunt run-all plan --terragrunt-log-level debug
```

## Best Practices

1. **Use meaningful environment names**: dev, staging, prod
2. **Version control**: Commit all Terragrunt configurations
3. **Documentation**: Document environment-specific configurations
4. **Testing**: Test changes in dev before applying to production
5. **Backup**: Regularly backup state files
6. **Security**: Use secure methods for sensitive variables

## Next Steps

1. Create additional environments (staging, prod)
2. Add more resources (monitoring, logging)
3. Implement CI/CD pipeline
4. Add security policies
5. Set up monitoring and alerting 