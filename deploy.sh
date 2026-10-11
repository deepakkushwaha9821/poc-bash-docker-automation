#!/usr/bin/env bash
# ==============================================================================
# Automated Docker Deployment Script
# POC of Bash and Docker Automation
# Usage: ./deploy <BRANCH> <SSH_HOST> [CONTAINER_NAME]
# Example: ./deploy main @ubuntu
#          ./deploy main ubuntu
# ==============================================================================

set -euo pipefail

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ------------------------------------------------------------------------------
# 1. Argument Validation
# ------------------------------------------------------------------------------
if [[ $# -lt 2 ]]; then
    echo -e "${BOLD}Usage:${NC} $0 <BRANCH> <SSH_HOST> [CONTAINER_NAME] [SERVICE_NAME]"
    echo ""
    echo "Arguments:"
    echo "  BRANCH          Git branch to deploy (e.g. main)"
    echo "  SSH_HOST        Configured SSH host or alias (e.g. @ubuntu or ubuntu)"
    echo "  CONTAINER_NAME  Target Docker container (default: poc-deploy-app)"
    echo "  SERVICE_NAME    Target systemd service (default: dummy-app.service)"
    echo ""
    echo "Example:"
    echo "  $0 main @ubuntu"
    echo "  $0 main ubuntu"
    exit 1
fi

BRANCH="$1"
RAW_HOST="$2"
SSH_HOST="${RAW_HOST#@}" # Strip leading '@' if present
CONTAINER_NAME="${3:-poc-deploy-app}"
SERVICE_NAME="${4:-dummy-app.service}"

echo -e "${BOLD}===================================================================${NC}"
echo -e "${BOLD}         POC of Bash and Docker Automation: Deploy Pipeline       ${NC}"
echo -e "${BOLD}===================================================================${NC}"
log_info "Target Branch:    ${BOLD}${BRANCH}${NC}"
log_info "SSH Host Alias:   ${BOLD}${SSH_HOST}${NC} (parsed from '${RAW_HOST}')"
log_info "Docker Container: ${BOLD}${CONTAINER_NAME}${NC}"
log_info "Systemd Service:  ${BOLD}${SERVICE_NAME}${NC}"
echo ""

# ------------------------------------------------------------------------------
# 2. Local Push to GitHub
# ------------------------------------------------------------------------------
log_info "Pushing branch '${BRANCH}' to GitHub via SSH..."
git push origin "${BRANCH}"
log_success "Branch '${BRANCH}' pushed to GitHub successfully!"
echo ""

# ------------------------------------------------------------------------------
# 3. SSH Connection & Remote Execution
# ------------------------------------------------------------------------------
log_info "Connecting to server via SSH (${SSH_HOST})..."

ssh -o BatchMode=yes "${SSH_HOST}" bash -s <<REMOTE_EXEC
set -euo pipefail

echo "==================== [Remote Server: ${SSH_HOST}] ===================="

# Verify Docker container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
    echo "[REMOTE ERROR] Container '${CONTAINER_NAME}' is not running on ${SSH_HOST}!"
    docker ps -a --filter "name=${CONTAINER_NAME}"
    exit 1
fi
echo "[REMOTE INFO] Target container '${CONTAINER_NAME}' is active."

# Execute deployment operations inside the container using docker exec
docker exec -i -u ubuntu -e BRANCH="${BRANCH}" -e SERVICE_NAME="${SERVICE_NAME}" "${CONTAINER_NAME}" bash <<'INSIDE_CONTAINER'
set -euo pipefail

echo "---------------- [Inside Container: ${CONTAINER_NAME}] ----------------"

# Step 1: Git Operations
echo ">> [1/5] Navigating to project directory & checking git state..."
cd /app
git config --global --add safe.directory /app

echo ">> Checking out branch '${BRANCH}'..."
git checkout "${BRANCH}"

if git remote get-url origin >/dev/null 2>&1; then
    echo ">> Pulling latest changes from origin/${BRANCH}..."
    git pull origin "${BRANCH}" || echo ">> Warning: git pull returned non-zero (continuing with local branch)."
else
    echo ">> No remote origin configured. Running deployment with current branch state."
fi

# Step 2: Build Frontend
echo ">> [2/5] Navigating to frontend directory..."
cd /app/frontend

echo ">> Installing frontend dependencies (npm ci)..."
npm ci --prefer-offline --no-audit

echo ">> Building frontend bundle (npm run build)..."
npm run build

# Step 3: Passwordless Sudo Service Restart
echo ">> [3/5] Restarting systemd service via passwordless sudo..."
sudo -n systemctl restart "${SERVICE_NAME}"

# Step 4: Verification of Service Status
echo ">> [4/5] Verifying service status with sudo -n systemctl status..."
sudo -n systemctl status "${SERVICE_NAME}" --no-pager

# Step 5: Verification of HTTP Health Check Endpoint
echo ">> [5/5] Testing HTTP health endpoint..."
sleep 1
if curl -sSf http://127.0.0.1:8000/api/health >/dev/null 2>&1; then
    echo "✓ Health check passed (HTTP 200 OK)!"
    curl -s http://127.0.0.1:8000/api/health
    echo ""
else
    echo "✗ Warning: Health check endpoint failed to respond."
    exit 1
fi

echo "---------------- [Deployment Inside Container Completed] ----------------"
INSIDE_CONTAINER

echo "==================== [Remote Deployment Finished] ===================="
REMOTE_EXEC

echo ""
log_success "Deployment completed successfully for branch '${BRANCH}' on '${SSH_HOST}'!"
