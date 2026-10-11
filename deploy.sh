#!/usr/bin/env bash
set -euo pipefail

BRANCH="$1"
SSH_HOST="${2#@}"
CONTAINER_NAME="poc-deploy-app"
SERVICE_NAME="dummy-app.service"

echo "=== Pushing ${BRANCH} to GitHub ==="
git push origin "${BRANCH}"

echo "=== Deploying to ${SSH_HOST} ==="
ssh "${SSH_HOST}" bash -s <<REMOTE_EXEC
set -euo pipefail

docker exec -i -u ubuntu "${CONTAINER_NAME}" bash <<INSIDE_CONTAINER
set -euo pipefail

echo "=== 1. Git checkout main then ${BRANCH} ==="
cd /app
git checkout main
git pull origin main
git checkout "${BRANCH}"
git pull origin "${BRANCH}"

echo "=== 2. Build Frontend ==="
cd /app/frontend
npm ci
npm run build

echo "=== 3. Restart Service via Passwordless Sudo ==="
sudo -n systemctl restart "${SERVICE_NAME}"
sudo -n systemctl status "${SERVICE_NAME}" --no-pager

echo "=== 4. Health Check ==="
sleep 1
curl -s http://127.0.0.1:8000/api/health
echo ""
INSIDE_CONTAINER

REMOTE_EXEC

echo "=== Deployment Complete ==="
