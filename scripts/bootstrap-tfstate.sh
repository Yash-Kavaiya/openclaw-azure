#!/usr/bin/env bash
# ============================================================
# Bootstrap Terraform Remote State Storage in Azure
# Run ONCE before first terraform init
# ============================================================
set -euo pipefail

# ---- Configuration ----
SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
LOCATION="${LOCATION:-eastus2}"
RESOURCE_GROUP="${TF_BACKEND_RG:-openclaw-tfstate-rg}"
STORAGE_ACCOUNT="${TF_BACKEND_SA:-openclawtfstate$RANDOM}"
CONTAINER_NAME="tfstate"

echo "=================================================="
echo "  OpenClaw - Terraform State Bootstrap"
echo "=================================================="
echo "  Subscription: $SUBSCRIPTION_ID"
echo "  Location:     $LOCATION"
echo "  RG:           $RESOURCE_GROUP"
echo "  SA:           $STORAGE_ACCOUNT"
echo "=================================================="
echo ""

# Set subscription
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group
echo "Creating resource group: $RESOURCE_GROUP"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags Project=openclaw ManagedBy=bootstrap

# Create storage account
echo "Creating storage account: $STORAGE_ACCOUNT"
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --https-only true \
  --tags Project=openclaw ManagedBy=bootstrap

# Enable versioning
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --enable-versioning true

# Create container
echo "Creating container: $CONTAINER_NAME"
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login

echo ""
echo "=================================================="
echo "  Bootstrap complete! Add these to your pipeline:"
echo "=================================================="
echo "  TF_BACKEND_RG=$RESOURCE_GROUP"
echo "  TF_BACKEND_SA=$STORAGE_ACCOUNT"
echo "  TF_BACKEND_CONTAINER=$CONTAINER_NAME"
echo ""
echo "  Uncomment the backend block in terraform/providers.tf"
echo "  and update with the values above."
echo "=================================================="
