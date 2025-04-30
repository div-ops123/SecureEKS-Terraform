#!/bin/bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: This script must be sourced (run with 'source $0' or '. $0') to export credentials."
  exit 1
fi


# ------------------------------
# Declare variables
# ------------------------------
ENV_FILE=".env"
ACCESS_KEY=$(terraform output -raw eks_admin_user_access_key_id 2>/dev/null)
SECRET_KEY=$(terraform output -raw eks_admin_user_secret_access_key 2>/dev/null)
USER_NAME=$(terraform output -raw eks_admin_user_name 2>/dev/null)
ROLE_ARN=$(terraform output -raw eks_admin_role_arn 2>/dev/null)
SESSION_NAME="eks-admin-session"
CLUSTER_NAME="my-first-cluster"
NEW_PROFILE="assumed-admin-role"
CREDENTIALS_JSON=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "$SESSION_NAME" --profile "$USER_NAME" 2>/dev/null)


# ------------------------------
# 1. Load .env File
# ------------------------------

# If .env file does not exist, create it from Terraform outputs
if [ ! -f "$ENV_FILE" ]; then
  echo ".env file not found! Creating from Terraform outputs..."

  # Check if Terraform outputs are available
  if ! terraform output -json > /dev/null 2>&1; then
    echo "Error: Failed to access Terraform outputs. Ensure 'terraform apply' has been run and outputs are defined."
    exit 1
  fi

  if [ -z "$ACCESS_KEY" ]; then
    echo "Error: Failed to retrieve eks_admin_user_access_key_id. Check Terraform outputs."
    exit 1
  fi

  if [ -z "$SECRET_KEY" ]; then
    echo "Error: Failed to retrieve eks_admin_user_secret_access_key. Check Terraform outputs."
    exit 1
  fi

  cat <<EOF > "$ENV_FILE"
AWS_ACCESS_KEY_ID=$ACCESS_KEY
AWS_SECRET_ACCESS_KEY=$SECRET_KEY
AWS_REGION=af-south-1
EOF

  echo "✅ .env file created successfully!"
fi

# Now source the environment variables
echo "Loading AWS credentials from .env..."
if ! source "$ENV_FILE"; then
  echo "Error: Failed to source $ENV_FILE. Ensure it contains valid AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION."
  exit 1
fi

# ------------------------------
# 2. Set Script Variables
# ------------------------------
if [ -z "$USER_NAME" ] || [ -z "$ROLE_ARN" ]; then
  echo "Error: Missing USER_NAME or ROLE_ARN. Check Terraform outputs."
  exit 1
fi

# ------------------------------
# 3. Configure AWS CLI Profile
# ------------------------------
echo "Setting up AWS CLI profile for user: $USER_NAME..."
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$USER_NAME"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$USER_NAME"
aws configure set region "$AWS_REGION" --profile "$USER_NAME"

# ------------------------------
# 4. Assume the IAM Role
# ------------------------------
echo "Assuming role: $ROLE_ARN..."
if [ $? -ne 0 ]; then
  echo "Error: Failed to assume role $ROLE_ARN. Check credentials and IAM policies."
  exit 1
fi


if ! echo "$CREDENTIALS_JSON" | jq . >/dev/null 2>&1; then
  echo "Error: Invalid JSON response from assume-role."
  exit 1
fi

# ------------------------------
# 5. Export Temporary Credentials
# ------------------------------
export AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS_JSON" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS_JSON" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$CREDENTIALS_JSON" | jq -r '.Credentials.SessionToken')


if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
  echo "Error: Failed to extract temporary credentials from assume-role response."
  exit 1
fi


# Save to a new profile for persistence
echo "Saving temporary credentials to profile: $NEW_PROFILE ..."
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$NEW_PROFILE"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$NEW_PROFILE"
aws configure set aws_session_token "$AWS_SESSION_TOKEN" --profile "$NEW_PROFILE"
aws configure set region "$AWS_REGION" --profile "$NEW_PROFILE"

echo "✅ Role assumed successfully!"
echo "Current AWS Identity:"
aws sts get-caller-identity --profile "$NEW_PROFILE"

# ------------------------------
# 6. Update Kubeconfig for EKS
# ------------------------------
echo "Updating kubeconfig for the EKS cluster..."
if ! aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME" --profile "$NEW_PROFILE"; then
  echo "Error: Failed to update kubeconfig for cluster $CLUSTER_NAME."
  exit 1
fi


echo "✅ All Done! Use 'kubectl' with profile '$NEW_PROFILE' (e.g., 'aws --profile $NEW_PROFILE eks ...')."


# unset AWS_ACCESS_KEY_ID
# unset AWS_SECRET_ACCESS_KEY
# unset AWS_SESSION_TOKEN
# aws sts get-caller-identity