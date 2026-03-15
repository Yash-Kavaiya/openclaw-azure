#!/usr/bin/env bash
# ============================================================
# OpenClaw Full Terraform Deploy Script
# Handles init, plan, and optionally apply
# ============================================================
set -euo pipefail

ENVIRONMENT="${1:-dev}"
ACTION="${2:-plan}"   # plan | apply | destroy
TF_DIR="$(dirname "$0")/../terraform"
VAR_FILE="${TF_DIR}/environments/${ENVIRONMENT}/terraform.tfvars"

# Check required env vars
: "${ARM_SUBSCRIPTION_ID:?ARM_SUBSCRIPTION_ID must be set}"
: "${TF_BACKEND_RG:?TF_BACKEND_RG must be set}"
: "${TF_BACKEND_SA:?TF_BACKEND_SA must be set}"
: "${TF_VAR_postgres_admin_password:?TF_VAR_postgres_admin_password must be set}"

echo "=================================================="
echo "  OpenClaw Terraform Deploy"
echo "  Environment: $ENVIRONMENT"
echo "  Action:      $ACTION"
echo "  Var file:    $VAR_FILE"
echo "=================================================="

if [[ ! -f "$VAR_FILE" ]]; then
  echo "ERROR: Variable file not found: $VAR_FILE"
  exit 1
fi

cd "$TF_DIR"

# ---- Init ----
echo ""
echo "→ Terraform Init..."
terraform init \
  -backend-config="resource_group_name=${TF_BACKEND_RG}" \
  -backend-config="storage_account_name=${TF_BACKEND_SA}" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=openclaw-${ENVIRONMENT}.terraform.tfstate" \
  -upgrade

# ---- Validate ----
echo ""
echo "→ Terraform Validate..."
terraform validate

# ---- Format check ----
echo ""
echo "→ Format check..."
terraform fmt -check -recursive || echo "⚠ Some files need formatting (run: terraform fmt -recursive)"

# ---- Plan ----
echo ""
echo "→ Terraform Plan..."
terraform plan \
  -var-file="${VAR_FILE}" \
  -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
  -out="tfplan-${ENVIRONMENT}"

if [[ "$ACTION" == "plan" ]]; then
  echo ""
  echo "Plan complete. To apply, run:"
  echo "  ACTION=apply $0 $ENVIRONMENT apply"
  exit 0
fi

# ---- Apply ----
if [[ "$ACTION" == "apply" ]]; then
  echo ""
  if [[ "${ENVIRONMENT}" == "prod" ]]; then
    read -p "⚠️  Applying to PRODUCTION. Are you sure? [yes/N]: " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
      echo "Aborted."
      exit 1
    fi
  fi

  echo "→ Terraform Apply..."
  terraform apply "tfplan-${ENVIRONMENT}"

  echo ""
  echo "→ Outputs:"
  terraform output
fi

# ---- Destroy ----
if [[ "$ACTION" == "destroy" ]]; then
  echo ""
  read -p "⚠️  DESTROYING ${ENVIRONMENT} environment. This cannot be undone! Type '${ENVIRONMENT}' to confirm: " CONFIRM
  if [[ "$CONFIRM" != "${ENVIRONMENT}" ]]; then
    echo "Aborted."
    exit 1
  fi

  echo "→ Terraform Destroy..."
  terraform destroy \
    -var-file="${VAR_FILE}" \
    -var="subscription_id=${ARM_SUBSCRIPTION_ID}" \
    -auto-approve
fi

echo ""
echo "=================================================="
echo "  Done!"
echo "=================================================="
