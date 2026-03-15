# OpenClaw Azure Deployment

Full end-to-end Infrastructure-as-Code and CI/CD pipeline to host **OpenClaw** (Legal Research Platform) directly on Azure Virtual Machines.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Subscription                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Resource Group                        │   │
│  │                                                          │   │
│  │  ┌────────┐   ┌──────────┐   ┌───────────────────────┐ │   │
│  │  │ Bastion│   │  Nginx   │   │   App VM(s)            │ │   │
│  │  │  Host  │   │ (Reverse │──▶│   Ubuntu 24.04         │ │   │
│  │  └────────┘   │  Proxy)  │   │   Docker + OpenClaw    │ │   │
│  │               └──────────┘   └──────────┬────────────┘ │   │
│  │                                          │              │   │
│  │  ┌──────────────────────────────────────▼────────────┐ │   │
│  │  │                   VNet (10.0.0.0/16)               │ │   │
│  │  │  subnet-app (10.0.1.0/24) | subnet-db (10.0.2.0) │ │   │
│  │  └───────────────────────────────────────────────────┘ │   │
│  │                                                          │   │
│  │  ┌──────────────┐  ┌────────────┐  ┌─────────────────┐ │   │
│  │  │  PostgreSQL   │  │   Redis    │  │   Key Vault     │ │   │
│  │  │  Flexible    │  │   Cache    │  │   (secrets)     │ │   │
│  │  │  Server      │  │            │  │                 │ │   │
│  │  └──────────────┘  └────────────┘  └─────────────────┘ │   │
│  │                                                          │   │
│  │  ┌──────────────┐  ┌────────────┐  ┌─────────────────┐ │   │
│  │  │  Container   │  │  Storage   │  │   App Insights  │ │   │
│  │  │  Registry    │  │  Account   │  │   + Log Anal.   │ │   │
│  │  └──────────────┘  └────────────┘  └─────────────────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Repository Structure

```
openclaw-azure/
├── app/                          # FastAPI application
│   ├── main.py                   # App entry point
│   ├── config.py                 # Settings (env vars)
│   ├── database.py               # SQLAlchemy async engine
│   ├── models.py                 # ORM models
│   ├── routers/
│   │   ├── auth.py               # JWT authentication
│   │   ├── cases.py              # Case CRUD
│   │   ├── search.py             # Full-text search
│   │   └── health.py             # Health/readiness probes
│   ├── requirements.txt
│   └── .env.example
├── terraform/
│   ├── main.tf                   # Root module
│   ├── variables.tf              # All variables
│   ├── outputs.tf                # All outputs
│   ├── providers.tf              # Provider configuration
│   ├── modules/
│   │   ├── networking/           # VNet, subnets, NSGs, Bastion
│   │   ├── compute/              # VMs, NICs, cloud-init
│   │   ├── database/             # PostgreSQL + Redis
│   │   └── security/             # Key Vault
│   └── environments/
│       ├── dev/terraform.tfvars
│       └── prod/terraform.tfvars
├── Dockerfile                    # Multi-stage Docker build
├── docker-compose.yml            # Local development
├── nginx/nginx.conf              # Nginx reverse proxy config
├── azure-pipelines.yml           # Azure DevOps full pipeline
├── .github/workflows/
│   ├── terraform.yml             # GitHub Actions - Terraform
│   ├── deploy.yml                # GitHub Actions - Build & Deploy
│   └── pr-check.yml              # GitHub Actions - PR quality gate
└── scripts/
    ├── bootstrap-tfstate.sh      # One-time: create TF state backend
    ├── setup-vm.sh               # Manual VM setup
    ├── deploy.sh                 # Manual deployment
    └── terraform-deploy.sh       # Terraform wrapper script
```

## Prerequisites

- Azure CLI (`az login`)
- Terraform >= 1.9
- Docker
- Python 3.12+
- Azure subscription with Contributor access

## Quick Start

### 1. Bootstrap Terraform State

```bash
export ARM_SUBSCRIPTION_ID="your-subscription-id"
bash scripts/bootstrap-tfstate.sh
```

### 2. Configure Variables

```bash
# Edit the tfvars file with your subscription ID and passwords
vi terraform/environments/dev/terraform.tfvars
```

### 3. Deploy Infrastructure

```bash
export TF_BACKEND_RG="openclaw-tfstate-rg"
export TF_BACKEND_SA="your-storage-account"
export TF_VAR_postgres_admin_password="YourStrongPassword1!"
export ARM_SUBSCRIPTION_ID="your-subscription-id"

bash scripts/terraform-deploy.sh dev plan   # Preview changes
bash scripts/terraform-deploy.sh dev apply  # Apply
```

### 4. Local Development

```bash
cp app/.env.example app/.env
# Edit app/.env with your local settings

docker-compose up -d
# App:     http://localhost:8000
# Docs:    http://localhost:8000/api/docs
# Adminer: docker-compose --profile dev up
```

## CI/CD Pipeline

### Azure DevOps (azure-pipelines.yml)

6-stage pipeline:

| Stage | Trigger | Description |
|-------|---------|-------------|
| Build & Test | All branches | Lint, test, Docker build & push |
| TF Plan Dev | develop/main | Terraform plan for dev env |
| TF Apply Dev | develop branch | Auto-apply dev infrastructure |
| Deploy Dev | develop branch | Rolling deploy to dev VMs |
| TF Plan Prod | main branch | Terraform plan for prod env |
| TF Apply + Deploy Prod | main branch | **Manual approval** + blue-green deploy |

**Required ADO Variable Groups:**
- `openclaw-global`: `ARM_SUBSCRIPTION_ID`, `AZURE_SERVICE_CONNECTION`, `TF_BACKEND_RG`, `TF_BACKEND_SA`, `ACR_NAME`
- `openclaw-dev-secrets`: `POSTGRES_ADMIN_PASSWORD_DEV`
- `openclaw-prod-secrets`: `POSTGRES_ADMIN_PASSWORD_PROD`

### GitHub Actions

| Workflow | File | Purpose |
|----------|------|---------|
| Build & Deploy | `deploy.yml` | Test → Scan → Build → Deploy |
| Terraform | `terraform.yml` | Validate → Plan → Apply (OIDC) |
| PR Check | `pr-check.yml` | Fast quality gate on PRs |

**Required GitHub Secrets:**
```
AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID
TF_BACKEND_RG, TF_BACKEND_SA
ACR_NAME, ACR_LOGIN_SERVER
POSTGRES_ADMIN_PASSWORD_DEV, POSTGRES_ADMIN_PASSWORD_PROD
DEV_RESOURCE_GROUP, PROD_RESOURCE_GROUP
```

## Azure Resources Created

| Resource | Dev SKU | Prod SKU |
|----------|---------|----------|
| VM | Standard_B2s (1x) | Standard_D4s_v3 (2x) |
| PostgreSQL Flexible | B_Standard_B1ms | GP_Standard_D2s_v3 |
| Redis Cache | Standard C1 | Standard C2 |
| Container Registry | Basic | Premium |
| Key Vault | Standard | Standard |
| Storage Account | Standard LRS | Standard GRS |
| App Insights | Workspace-based | Workspace-based |
| Azure Bastion | — | Standard |

## Security Highlights

- All secrets in Azure Key Vault
- VMs use Managed Identity (no credentials in code)
- PostgreSQL in private subnet, no public endpoint
- NSG: DB subnet only accepts traffic from App subnet
- SSH via Azure Bastion (no public SSH in prod)
- UFW + fail2ban on VMs
- TLS 1.2+ enforced everywhere
- Docker runs as non-root user
- Container images scanned with Trivy + Checkov/tfsec

## Manual Deploy

```bash
export ACR_NAME="openclawdevacr"
export RG_NAME="openclaw-dev-rg"
bash scripts/deploy.sh dev sha-abc1234
```
