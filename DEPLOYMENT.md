# 🚀 OpenClaw Azure Deployment — GitHub Actions Only

No local Docker, Terraform, or Azure CLI required. Everything runs in GitHub Actions.

---

## Prerequisites

1. **Azure Subscription** with Contributor access
2. **GitHub Repository** — `Yash-Kavaiya/openclaw-azure`

---

## Step-by-Step Setup

### Step 1: Create Azure Service Principal (OIDC / Federated)

Run this once from [Azure Cloud Shell](https://shell.azure.com) (no local install needed):

```bash
# Set your subscription
SUBSCRIPTION_ID="<your-subscription-id>"
APP_NAME="openclaw-github-actions"
GITHUB_ORG="Yash-Kavaiya"
GITHUB_REPO="openclaw-azure"

# Create App Registration
az ad app create --display-name "$APP_NAME" --query appId -o tsv
# Save the output as AZURE_CLIENT_ID

# Create Service Principal
az ad sp create --id <AZURE_CLIENT_ID>

# Assign Contributor role on subscription
az role assignment create \
  --assignee <AZURE_CLIENT_ID> \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID

# Create Federated Credentials for GitHub Actions
# For main branch:
az ad app federated-credential create --id <AZURE_CLIENT_ID> --parameters '{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'"$GITHUB_ORG/$GITHUB_REPO"':ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# For develop branch:
az ad app federated-credential create --id <AZURE_CLIENT_ID> --parameters '{
  "name": "github-develop",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'"$GITHUB_ORG/$GITHUB_REPO"':ref:refs/heads/develop",
  "audiences": ["api://AzureADTokenExchange"]
}'

# For pull requests:
az ad app federated-credential create --id <AZURE_CLIENT_ID> --parameters '{
  "name": "github-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'"$GITHUB_ORG/$GITHUB_REPO"':pull_request",
  "audiences": ["api://AzureADTokenExchange"]
}'

# For bootstrap environment:
az ad app federated-credential create --id <AZURE_CLIENT_ID> --parameters '{
  "name": "github-bootstrap",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'"$GITHUB_ORG/$GITHUB_REPO"':environment:bootstrap",
  "audiences": ["api://AzureADTokenExchange"]
}'

# For dev environment:
az ad app federated-credential create --id <AZURE_CLIENT_ID> --parameters '{
  "name": "github-dev",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'"$GITHUB_ORG/$GITHUB_REPO"':environment:dev",
  "audiences": ["api://AzureADTokenExchange"]
}'

# For dev-plan environment:
az ad app federated-credential create --id <AZURE_CLIENT_ID> --parameters '{
  "name": "github-dev-plan",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'"$GITHUB_ORG/$GITHUB_REPO"':environment:dev-plan",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Get your Tenant ID:
az account show --query tenantId -o tsv
```

### Step 2: Set GitHub Secrets

Go to **Settings → Secrets and variables → Actions** in your repo and add:

| Secret | Description | Example |
|--------|-------------|---------|
| `AZURE_CLIENT_ID` | App Registration Client ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `POSTGRES_ADMIN_PASSWORD_DEV` | DB password for dev | `YourStr0ngP@ssw0rd!` |
| `POSTGRES_ADMIN_PASSWORD_PROD` | DB password for prod | `An0therStr0ngP@ss!` |

### Step 3: Create GitHub Environments

Go to **Settings → Environments** and create:

- `bootstrap` — no protection rules
- `dev-plan` — no protection rules
- `dev` — no protection rules
- `prod-plan` — no protection rules
- `prod` — add **Required reviewers** (yourself)

### Step 4: Run Bootstrap Workflow

1. Go to **Actions → Bootstrap**
2. Click **Run workflow**
3. Select `centralindia` for location
4. Enter `openclawtfstate` for storage account name
5. Run it

After it completes, add two more secrets:

| Secret | Value |
|--------|-------|
| `TF_BACKEND_RG` | `openclaw-tfstate-rg` |
| `TF_BACKEND_SA` | `openclawtfstate` |

### Step 5: Push to Develop Branch to Deploy Dev

```bash
git checkout -b develop
git push -u origin develop
```

This triggers:
1. **Terraform Validate** → format check + validate
2. **Security Scan** → tfsec + checkov
3. **Terraform Plan Dev** → preview what will be created
4. **Terraform Apply Dev** → provisions all Azure resources
5. **Build & Deploy** → builds Docker image, pushes to ACR, deploys to VMs

### Step 6: Deploy to Production

Merge `develop` → `main` via PR. The pipeline will:
1. Plan prod infrastructure
2. Wait for your manual approval
3. Apply infrastructure
4. Build, scan, and deploy with blue-green strategy

---

## What Gets Created (Dev)

| Resource | SKU | Est. Monthly Cost |
|----------|-----|-------------------|
| VM (1x) | Standard_B2s | ~$30 |
| PostgreSQL Flexible | B_Standard_B1ms | ~$13 |
| Redis Cache | Basic C0 | ~$16 |
| Container Registry | Basic | ~$5 |
| Key Vault | Standard | ~$0.03/secret |
| Storage Account | Standard LRS | ~$1 |
| Log Analytics | Per-GB | ~$2 |
| **Total Dev** | | **~$67/month** |

---

## Architecture

```
GitHub Actions (CI/CD)
    │
    ├── Terraform → Azure Resources
    │     ├── Resource Group (centralindia)
    │     ├── VNet + Subnets + NSGs
    │     ├── VM(s) with Docker + Nginx
    │     ├── PostgreSQL Flexible Server (private subnet)
    │     ├── Redis Cache
    │     ├── Container Registry (ACR)
    │     ├── Key Vault
    │     ├── Storage Account
    │     └── App Insights + Log Analytics
    │
    └── Docker Build → Push to ACR → Deploy to VM(s)
```

---

## Secrets Summary

After full setup, you should have these GitHub Secrets:

```
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
TF_BACKEND_RG
TF_BACKEND_SA
POSTGRES_ADMIN_PASSWORD_DEV
POSTGRES_ADMIN_PASSWORD_PROD
ACR_NAME (auto: openclaw-dev-acr or from TF output)
ACR_LOGIN_SERVER (auto: from TF output)
DEV_RESOURCE_GROUP (= openclaw-dev-rg)
PROD_RESOURCE_GROUP (= openclaw-prod-rg)
```
