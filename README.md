# POC of Bash and Docker Automation (`poc-bash-docker-automation`)

Proof of concept for automated deployment using Bash, Docker, SSH key authentication, and passwordless sudo service reloads.

## 📁 Project Structure

```
poc-bash-docker-automation/
├── Dockerfile                # Docker image with Node 20, Python3, Git, sudo, systemd service
├── deploy.sh                 # Bash deployment script (main automation entry point)
├── setup-container.sh        # Builds Docker image & starts container
├── backend/
│   └── server.py             # Python HTTP API server (/api/health, /api/info, static assets)
├── frontend/
│   ├── package.json          # Frontend build configuration
│   ├── package-lock.json     # Lockfile for reproducible npm ci builds
│   ├── vite.config.js        # Vite bundler configuration
│   ├── index.html            # Web dashboard interface
│   └── src/
│       ├── main.js           # Live API health check & UI logic
│       └── style.css         # Modern responsive styling
├── systemd/
│   ├── dummy-app.service     # Systemd service unit → copied to /etc/systemd/system/
│   └── sudoers-deploy-service # Sudoers rule → copied to /etc/sudoers.d/deploy-service
├── .gitignore
└── README.md
```

## 🛠️ Architecture & Implemented Plan

| Step | Requirement | Implementation | Status |
|---|---|---|---|
| **1** | **Bash Script** | [`deploy.sh`](deploy.sh) accepts branch and host arguments (e.g. `./deploy.sh poc-git @ubuntu`) | ✅ Verified |
| **2** | **Configure SSH** | SSH key auth & `Host ubuntu` alias in `~/.ssh/config` without password prompt | ✅ Verified |
| **3** | **Connect to Server** | SSH session → `docker exec -i -u ubuntu poc-deploy-app` inside container | ✅ Verified |
| **4** | **Git Operations** | `cd /app && git checkout <BRANCH> && git pull origin <BRANCH>` | ✅ Verified |
| **5** | **Build Frontend** | `cd /app/frontend && npm ci && npm run build` producing `/app/frontend/dist` | ✅ Verified |
| **6** | **Passwordless Sudo** | [`sudoers-deploy-service`](systemd/sudoers-deploy-service) → `/etc/sudoers.d/deploy-service` (via Dockerfile) | ✅ Verified |
| **7** | **Restart Service** | `sudo -n systemctl restart dummy-app.service` & verified with `systemctl status` + `curl /api/health` | ✅ Verified |

---

## 🚀 How to Run the POC

### 1. Build Docker Image & Start Container
```bash
./setup-container.sh
```
This runs `docker build` using the [`Dockerfile`](Dockerfile), then starts the container `poc-deploy-app` with systemd, the service, and the sudoers rule all pre-configured.

### 2. Run Automated Deployment
Deploy feature branch `poc-git`:
```bash
./deploy.sh poc-git @ubuntu
```

Deploy main branch:
```bash
./deploy.sh main @ubuntu
```

---

## 🐳 Dockerfile

The [`Dockerfile`](Dockerfile) builds a self-contained image with:
- **Base**: `jrei/systemd-ubuntu:22.04` (Ubuntu 22.04 with systemd)
- **Packages**: Python3, Node.js 20, npm, Git, sudo, curl
- **Service**: `dummy-app.service` copied to `/etc/systemd/system/` and enabled
- **Security**: `sudoers-deploy-service` copied to `/etc/sudoers.d/deploy-service`
- **Port**: 8000 exposed

---

## 🔒 Restricted Passwordless Sudo Rule

Source file: [`systemd/sudoers-deploy-service`](systemd/sudoers-deploy-service)
Installed to: `/etc/sudoers.d/deploy-service` inside the container (via Dockerfile COPY)

```sudoers
ubuntu ALL=(ALL) NOPASSWD: /bin/systemctl restart dummy-app.service*, ...
```
- Allows `sudo -n systemctl restart dummy-app.service` without password.
- Blocks any other service or unauthorized command.

---

## 🔑 SSH Configuration

Configured in `~/.ssh/config`:
```sshconfig
Host ubuntu
    HostName 127.0.0.1
    User deepak
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking accept-new
```

---

## 📦 GitHub Repository Setup

```bash
git remote add origin https://github.com/deepakkushwaha9821/poc-bash-docker-automation.git
git push -u origin main
git push -u origin poc-git
```
