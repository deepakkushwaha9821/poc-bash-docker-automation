# ==============================================================================
# Dockerfile for POC of Bash and Docker Automation
# Base: Ubuntu 22.04 with systemd support
# Includes: Python3, Node.js 20, npm, Git, sudo, curl
# ==============================================================================

FROM jrei/systemd-ubuntu:22.04

# Install base dependencies
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        sudo \
        curl \
        git \
        python3 \
        openssh-client \
        ca-certificates \
        gnupg && \
    # Install Node.js 20.x from NodeSource
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y -qq nodejs && \
    # Cleanup apt cache to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create deploy user 'ubuntu' with home directory
RUN useradd -m -s /bin/bash ubuntu

# Configure restricted passwordless sudo for deploy user
# Only allows systemctl commands for dummy-app.service
COPY etc/sudoers.d/deploy-service /etc/sudoers.d/deploy-service
RUN chmod 0440 /etc/sudoers.d/deploy-service && \
    visudo -cf /etc/sudoers.d/deploy-service

# Copy systemd service unit file to /etc/systemd/system/
COPY etc/systemd/system/dummy-app.service /etc/systemd/system/dummy-app.service
RUN chmod 644 /etc/systemd/system/dummy-app.service && \
    systemctl enable dummy-app.service

# Set working directory
WORKDIR /app

# Expose application port
EXPOSE 8000

# systemd is the init process (provided by base image)
