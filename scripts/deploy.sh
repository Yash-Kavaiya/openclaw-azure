#!/usr/bin/env bash
# ============================================================
# OpenClaw Manual Deployment Script
# Usage: ./scripts/deploy.sh [dev|prod] [image-tag]
# ============================================================
set -euo pipefail

ENVIRONMENT="${1:-dev}"
IMAGE_TAG="${2:-latest}"
ACR_NAME="${ACR_NAME:-}"
RG_NAME="${RG_NAME:-openclaw-${ENVIRONMENT}-rg}"

if [[ -z "$ACR_NAME" ]]; then
  echo "ERROR: ACR_NAME environment variable is required"
  exit 1
fi

IMAGE="${ACR_NAME}.azurecr.io/openclaw:${IMAGE_TAG}"

echo "=================================================="
echo "  OpenClaw Deployment"
echo "  Environment: $ENVIRONMENT"
echo "  Image:       $IMAGE"
echo "  RG:          $RG_NAME"
echo "=================================================="

# Check Azure CLI
if ! command -v az &>/dev/null; then
  echo "ERROR: Azure CLI not found. Install from https://aka.ms/install-azure-cli"
  exit 1
fi

# Check logged in
az account show &>/dev/null || { echo "ERROR: Not logged in. Run: az login"; exit 1; }

# Get VMs
VMS=$(az vm list -g "$RG_NAME" --query "[].name" -o tsv 2>/dev/null)
if [[ -z "$VMS" ]]; then
  echo "ERROR: No VMs found in $RG_NAME"
  exit 1
fi

VM_COUNT=$(echo "$VMS" | wc -l)
echo "Found $VM_COUNT VM(s): $(echo $VMS | tr '\n' ' ')"
echo ""

# Deploy to each VM
IDX=1
FAILED=0

for VM in $VMS; do
  echo "[$IDX/$VM_COUNT] Deploying to $VM..."

  az vm run-command invoke \
    -g "$RG_NAME" -n "$VM" \
    --command-id RunShellScript \
    --scripts "
      set -e
      az acr login --name ${ACR_NAME} --identity 2>/dev/null || \
        docker login ${ACR_NAME}.azurecr.io -u \"\$ACR_ADMIN_USERNAME\" -p \"\$ACR_ADMIN_PASSWORD\"

      echo 'Pulling image: ${IMAGE}'
      docker pull ${IMAGE}

      echo 'Stopping existing container...'
      docker stop openclaw 2>/dev/null || true
      docker rm openclaw 2>/dev/null || true

      echo 'Starting new container...'
      docker run -d --name openclaw --restart always \
        --env-file /etc/openclaw/environment \
        -p 8000:8000 \
        ${IMAGE}

      echo 'Waiting for health check...'
      for i in \$(seq 1 12); do
        sleep 5
        curl -sf http://localhost:8000/api/health && { echo 'Health check passed!'; exit 0; }
        echo \"Attempt \$i/12 failed, retrying...\"
      done
      echo 'Health check failed after 60s'
      docker logs openclaw --tail 50
      exit 1
    " \
    --output table

  if [[ $? -eq 0 ]]; then
    echo "✓ [$IDX/$VM_COUNT] $VM: deployed successfully"
  else
    echo "✗ [$IDX/$VM_COUNT] $VM: deployment FAILED"
    FAILED=$((FAILED + 1))
  fi

  IDX=$((IDX + 1))
done

echo ""
echo "=================================================="
if [[ $FAILED -eq 0 ]]; then
  echo "  ✅ Deployment complete: $VM_COUNT/$VM_COUNT VMs successful"

  # Print VM IPs
  echo ""
  echo "  Application URLs:"
  for VM in $VMS; do
    IP=$(az vm list-ip-addresses -g "$RG_NAME" -n "$VM" \
      --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv 2>/dev/null || echo "N/A")
    echo "  - $VM: http://$IP"
  done
else
  echo "  ❌ Deployment FAILED: $FAILED/$VM_COUNT VMs failed"
  exit 1
fi
echo "=================================================="
