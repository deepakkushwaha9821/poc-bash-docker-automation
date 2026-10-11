#!/usr/bin/env bash
# ==============================================================================
# Setup script: Build Docker image & run container from Dockerfile
# POC of Bash and Docker Automation
# Usage: ./setup-container.sh
# ==============================================================================

set -euo pipefail

CONTAINER_NAME="poc-deploy-app"
IMAGE_NAME="poc-deploy-app:latest"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== 1. Building Docker image '${IMAGE_NAME}' from Dockerfile ==="
docker build -t "${IMAGE_NAME}" "${PROJECT_DIR}"

echo ""
echo "=== 2. Removing old container '${CONTAINER_NAME}' (if exists) ==="
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
    docker rm -f "${CONTAINER_NAME}"
    echo "   Removed."
else
    echo "   No existing container found."
fi

echo ""
echo "=== 3. Starting new container '${CONTAINER_NAME}' ==="
docker run -d \
    --name "${CONTAINER_NAME}" \
    --privileged \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    --cgroupns=host \
    -v "${PROJECT_DIR}:/app" \
    -p 8000:8000 \
    "${IMAGE_NAME}"

echo ""
echo "=== 4. Waiting for systemd to initialize... ==="
sleep 2
docker exec "${CONTAINER_NAME}" systemctl is-system-running || true

echo ""
echo "=== 5. Setting file ownership for deploy user ==="
docker exec "${CONTAINER_NAME}" chown -R ubuntu:ubuntu /app

echo ""
echo "=== 6. Reloading and starting dummy-app service ==="
docker exec "${CONTAINER_NAME}" bash -c "
    systemctl daemon-reload
    systemctl restart dummy-app.service
    systemctl status dummy-app.service --no-pager
"

echo ""
echo "=== Setup complete! ==="
echo "Container '${CONTAINER_NAME}' is ready."
echo "Run deployment with:  ./deploy poc-git @ubuntu"
