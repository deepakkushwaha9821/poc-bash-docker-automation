#!/usr/bin/env bash
# ==============================================================================
# Setup script to provision the target Docker container environment
# POC of Bash and Docker Automation
# ==============================================================================

set -euo pipefail

CONTAINER_NAME="poc-deploy-app"
IMAGE="jrei/systemd-ubuntu:22.04"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== 1. Starting systemd container '${CONTAINER_NAME}' ==="
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}\$"; then
    echo "Removing existing container '${CONTAINER_NAME}'..."
    docker rm -f "${CONTAINER_NAME}"
fi

docker run -d \
    --name "${CONTAINER_NAME}" \
    --privileged \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    --cgroupns=host \
    -v "${PROJECT_DIR}:/app" \
    -p 8000:8000 \
    "${IMAGE}"

echo "=== 2. Installing container dependencies (Node 20, Git, sudo, curl) ==="
docker exec "${CONTAINER_NAME}" bash -c "
    apt-get update -qq
    apt-get install -y -qq sudo curl git python3
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y -qq nodejs
"

echo "=== 3. Configuring deploy user and restricted sudoers rule ==="
docker exec "${CONTAINER_NAME}" bash -c "
    id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu
    chown -R ubuntu:ubuntu /app

    cat << 'EOF' > /etc/sudoers.d/deploy-service
# Restricted sudoers rule allowing only systemctl commands for dummy-app.service
ubuntu ALL=(ALL) NOPASSWD: /bin/systemctl restart dummy-app.service*, /usr/bin/systemctl restart dummy-app.service*, /bin/systemctl status dummy-app.service*, /usr/bin/systemctl status dummy-app.service*, /bin/systemctl is-active dummy-app.service*, /usr/bin/systemctl is-active dummy-app.service*
EOF
    chmod 0440 /etc/sudoers.d/deploy-service
    visudo -cf /etc/sudoers.d/deploy-service
"

echo "=== 4. Installing and enabling dummy-app systemd service ==="
docker exec "${CONTAINER_NAME}" bash -c "
    cp /app/systemd/dummy-app.service /etc/systemd/system/dummy-app.service
    chmod 644 /etc/systemd/system/dummy-app.service
    systemctl daemon-reload
    systemctl enable dummy-app.service
    systemctl restart dummy-app.service
    systemctl status dummy-app.service --no-pager
"

echo "=== Setup complete! Target container '${CONTAINER_NAME}' is ready. ==="
