# Automated Docker Deployment POC (`docker-bash-deploy-poc`)

Proof of concept dummy project for automated deployment using Bash, SSH key authentication, Docker container execution, Vite frontend builds, and passwordless sudo service reloads.

## 📁 Project Structure

```
docker-bash-deploy-poc/
├── backend/
│   └── server.py             # Lightweight HTTP API & static asset server
├── frontend/
│   ├── package.json          # Frontend build configuration
│   ├── package-lock.json     # Lockfile for reproducible npm ci builds
│   ├── vite.config.js        # Vite bundler configuration
│   ├── index.html            # Web dashboard interface
│   └── src/
│       ├── main.js           # Live API check & UI logic
│       └── style.css         # Modern responsive styling
├── systemd/
│   └── dummy-app.service     # Systemd service unit for systemctl management
├── .gitignore
└── README.md
```

## 🚀 Components

1. **Backend**: Python 3 HTTP service exposing:
   - `GET /api/health`: Health status endpoint.
   - `GET /api/info`: Service metadata and frontend build detection.
   - Static asset serving for `frontend/dist`.
2. **Frontend**: Vite-based SPA supporting:
   - Fast, reproducible dependency installation via `npm ci`.
   - Production bundle output via `npm run build`.
3. **Service Management**:
   - `dummy-app.service` systemd unit configured for zero-downtime reloads via `sudo -n systemctl restart dummy-app.service`.

## 🔄 Upcoming POC Pipeline Steps

1. **Bash Deployment Script**: `./deploy <branch> <ssh-host>`
2. **SSH Authentication**: Passwordless SSH key alias (`~/.ssh/config`).
3. **Docker Execution**: Running commands inside target Docker container via `docker exec`.
4. **Git Operations**: `git checkout <branch>` & `git pull origin <branch>`.
5. **Frontend Build**: `npm ci && npm run build`.
6. **Passwordless Sudo**: `/etc/sudoers.d/deploy-service` rule for restricted `systemctl restart`.
7. **Service Verification**: Health check validation after reload.
